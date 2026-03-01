package ai.openclaw.wear

import android.content.Context
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.json.Json

class WatchDataLayerSender(private val context: Context) {

  private val json = Json { ignoreUnknownKeys = true }
  private val messageClient by lazy { Wearable.getMessageClient(context) }
  private val nodeClient by lazy { Wearable.getNodeClient(context) }

  data class SendResult(
    val success: Boolean,
    val errorMessage: String? = null,
  )

  suspend fun sendReply(reply: WatchReplyPayload): SendResult {
    val phoneNodeId = findPhoneNodeId() ?: return SendResult(
      success = false,
      errorMessage = "phone not connected",
    )

    val payloadBytes = json.encodeToString(WatchReplyPayload.serializer(), reply)
      .toByteArray(Charsets.UTF_8)

    return try {
      messageClient.sendMessage(
        phoneNodeId,
        WatchDataLayerReceiver.PATH_REPLY,
        payloadBytes,
      ).await()
      SendResult(success = true)
    } catch (e: Throwable) {
      SendResult(success = false, errorMessage = e.message ?: "send failed")
    }
  }

  private suspend fun findPhoneNodeId(): String? {
    return try {
      val nodes = nodeClient.connectedNodes.await()
      nodes.firstOrNull()?.id
    } catch (_: Throwable) {
      null
    }
  }
}
