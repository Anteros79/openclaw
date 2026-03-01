package ai.openclaw.wear

import android.content.Intent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.serialization.json.Json

class WatchDataLayerReceiver : WearableListenerService() {

  private val json = Json { ignoreUnknownKeys = true }

  override fun onMessageReceived(messageEvent: MessageEvent) {
    if (messageEvent.path != PATH_NOTIFY) return
    val payloadStr = String(messageEvent.data, Charsets.UTF_8)
    val payload = parseNotifyPayload(payloadStr) ?: return

    val app = applicationContext as? OpenClawWearApp ?: return
    app.onNotifyReceived(payload, transport = "message")
  }

  override fun onDataChanged(dataEvents: DataEventBuffer) {
    for (event in dataEvents) {
      if (event.dataItem.uri.path != PATH_NOTIFY_DATA) continue
      val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
      val payloadStr = dataMap.getString("payload") ?: continue
      val payload = parseNotifyPayload(payloadStr) ?: continue

      val app = applicationContext as? OpenClawWearApp ?: continue
      app.onNotifyReceived(payload, transport = "data")
    }
  }

  private fun parseNotifyPayload(raw: String): WatchNotifyPayload? {
    return try {
      val payload = json.decodeFromString<WatchNotifyPayload>(raw)
      if (payload.type != "watch.notify") return null
      if (payload.title.isBlank() && payload.body.isBlank()) return null
      payload
    } catch (_: Throwable) {
      null
    }
  }

  companion object {
    const val PATH_NOTIFY = "/openclaw/watch/notify"
    const val PATH_NOTIFY_DATA = "/openclaw/watch/notify/data"
    const val PATH_REPLY = "/openclaw/watch/reply"
  }
}
