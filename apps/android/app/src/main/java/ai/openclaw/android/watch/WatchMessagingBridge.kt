package ai.openclaw.android.watch

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class WatchNotifyParams(
  val title: String,
  val body: String,
  val promptId: String? = null,
  val sessionKey: String? = null,
  val kind: String? = null,
  val details: String? = null,
  val expiresAtMs: Long? = null,
  val risk: String? = null,
  val actions: List<WatchActionParam>? = null,
)

@Serializable
data class WatchActionParam(
  val id: String,
  val label: String,
  val style: String? = null,
)

@Serializable
data class WatchQuickReplyEvent(
  val type: String = "watch.reply",
  val replyId: String,
  val promptId: String,
  val actionId: String,
  val actionLabel: String? = null,
  val sessionKey: String? = null,
  val note: String? = null,
  val sentAtMs: Long? = null,
)

data class WatchMessagingStatus(
  val supported: Boolean,
  val connectedNodeCount: Int,
  val reachable: Boolean,
)

data class WatchNotifySendResult(
  val deliveredImmediately: Boolean,
  val queuedForDelivery: Boolean,
  val transport: String,
)

class WatchMessagingBridge(context: Context) : MessageClient.OnMessageReceivedListener {

  companion object {
    private const val TAG = "WatchBridge"
    private const val PATH_NOTIFY = "/openclaw/watch/notify"
    private const val PATH_NOTIFY_DATA = "/openclaw/watch/notify/data"
    private const val PATH_REPLY = "/openclaw/watch/reply"
  }

  private val appContext = context.applicationContext
  private val json = Json { ignoreUnknownKeys = true }
  private val messageClient: MessageClient = Wearable.getMessageClient(appContext)
  private val dataClient: DataClient = Wearable.getDataClient(appContext)
  private val capabilityClient: CapabilityClient = Wearable.getCapabilityClient(appContext)
  private val nodeClient = Wearable.getNodeClient(appContext)

  @Volatile
  private var replyHandler: ((WatchQuickReplyEvent) -> Unit)? = null

  fun activate() {
    messageClient.addListener(this)
  }

  fun deactivate() {
    messageClient.removeListener(this)
  }

  fun setReplyHandler(handler: ((WatchQuickReplyEvent) -> Unit)?) {
    replyHandler = handler
  }

  override fun onMessageReceived(messageEvent: MessageEvent) {
    if (messageEvent.path != PATH_REPLY) return
    try {
      val payloadStr = String(messageEvent.data, Charsets.UTF_8)
      val reply = json.decodeFromString<WatchQuickReplyEvent>(payloadStr)
      replyHandler?.invoke(reply)
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to parse watch reply: ${e.message}")
    }
  }

  suspend fun status(): WatchMessagingStatus {
    return try {
      val nodes = nodeClient.connectedNodes.await()
      WatchMessagingStatus(
        supported = true,
        connectedNodeCount = nodes.size,
        reachable = nodes.isNotEmpty(),
      )
    } catch (_: Throwable) {
      WatchMessagingStatus(supported = false, connectedNodeCount = 0, reachable = false)
    }
  }

  suspend fun sendNotification(id: String, params: WatchNotifyParams): WatchNotifySendResult {
    val payload = buildNotifyPayloadJson(id, params)
    val payloadBytes = payload.toByteArray(Charsets.UTF_8)

    // Try immediate delivery via MessageClient
    val watchNodeId = findWatchNodeId()
    if (watchNodeId != null) {
      try {
        messageClient.sendMessage(watchNodeId, PATH_NOTIFY, payloadBytes).await()
        return WatchNotifySendResult(
          deliveredImmediately = true,
          queuedForDelivery = false,
          transport = "message",
        )
      } catch (e: Throwable) {
        Log.w(TAG, "MessageClient send failed, falling back to DataClient: ${e.message}")
      }
    }

    // Fallback: queue via DataClient (synced when watch reconnects)
    try {
      val putDataReq = PutDataMapRequest.create(PATH_NOTIFY_DATA).apply {
        dataMap.putString("payload", payload)
        dataMap.putLong("timestamp", System.currentTimeMillis())
      }.asPutDataRequest().setUrgent()

      dataClient.putDataItem(putDataReq).await()
      return WatchNotifySendResult(
        deliveredImmediately = false,
        queuedForDelivery = true,
        transport = "data",
      )
    } catch (e: Throwable) {
      Log.e(TAG, "DataClient put failed: ${e.message}")
      throw e
    }
  }

  private fun buildNotifyPayloadJson(id: String, params: WatchNotifyParams): String {
    val sb = StringBuilder()
    sb.append("{")
    sb.append("\"type\":\"watch.notify\"")
    sb.append(",\"id\":").append(jsonString(id))
    sb.append(",\"title\":").append(jsonString(params.title))
    sb.append(",\"body\":").append(jsonString(params.body))
    sb.append(",\"sentAtMs\":").append(System.currentTimeMillis())
    params.promptId?.let { sb.append(",\"promptId\":").append(jsonString(it)) }
    params.sessionKey?.let { sb.append(",\"sessionKey\":").append(jsonString(it)) }
    params.kind?.let { sb.append(",\"kind\":").append(jsonString(it)) }
    params.details?.let { sb.append(",\"details\":").append(jsonString(it)) }
    params.expiresAtMs?.let { sb.append(",\"expiresAtMs\":").append(it) }
    params.risk?.let { sb.append(",\"risk\":").append(jsonString(it)) }
    params.actions?.let { actions ->
      if (actions.isNotEmpty()) {
        sb.append(",\"actions\":[")
        actions.forEachIndexed { i, action ->
          if (i > 0) sb.append(",")
          sb.append("{\"id\":").append(jsonString(action.id))
          sb.append(",\"label\":").append(jsonString(action.label))
          action.style?.let { sb.append(",\"style\":").append(jsonString(it)) }
          sb.append("}")
        }
        sb.append("]")
      }
    }
    sb.append("}")
    return sb.toString()
  }

  private fun jsonString(value: String): String {
    val escaped = value
      .replace("\\", "\\\\")
      .replace("\"", "\\\"")
      .replace("\n", "\\n")
      .replace("\r", "\\r")
      .replace("\t", "\\t")
    return "\"$escaped\""
  }

  private suspend fun findWatchNodeId(): String? {
    return try {
      val nodes = nodeClient.connectedNodes.await()
      nodes.firstOrNull()?.id
    } catch (_: Throwable) {
      null
    }
  }
}
