package ai.openclaw.android.node

import ai.openclaw.android.gateway.GatewaySession
import ai.openclaw.android.watch.WatchActionParam
import ai.openclaw.android.watch.WatchMessagingBridge
import ai.openclaw.android.watch.WatchNotifyParams
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import kotlinx.serialization.json.longOrNull
import java.util.UUID

class WatchHandler(
  private val bridge: WatchMessagingBridge,
  private val json: Json,
) {
  suspend fun handleStatus(@Suppress("UNUSED_PARAMETER") paramsJson: String?): GatewaySession.InvokeResult {
    val status = bridge.status()
    val payload = buildString {
      append("{")
      append("\"supported\":").append(status.supported)
      append(",\"connectedNodeCount\":").append(status.connectedNodeCount)
      append(",\"reachable\":").append(status.reachable)
      append("}")
    }
    return GatewaySession.InvokeResult.ok(payload)
  }

  suspend fun handleNotify(paramsJson: String?): GatewaySession.InvokeResult {
    if (paramsJson.isNullOrBlank()) {
      return GatewaySession.InvokeResult.error(
        code = "INVALID_REQUEST",
        message = "INVALID_REQUEST: watch.notify requires title and body",
      )
    }

    val params = try {
      parseNotifyParams(paramsJson)
    } catch (e: Throwable) {
      return GatewaySession.InvokeResult.error(
        code = "INVALID_REQUEST",
        message = "INVALID_REQUEST: ${e.message}",
      )
    }

    if (params.title.isBlank() && params.body.isBlank()) {
      return GatewaySession.InvokeResult.error(
        code = "INVALID_REQUEST",
        message = "INVALID_REQUEST: title or body required",
      )
    }

    val id = UUID.randomUUID().toString()
    return try {
      val result = bridge.sendNotification(id, params)
      val payload = buildString {
        append("{")
        append("\"deliveredImmediately\":").append(result.deliveredImmediately)
        append(",\"queuedForDelivery\":").append(result.queuedForDelivery)
        append(",\"transport\":\"").append(result.transport).append("\"")
        append("}")
      }
      GatewaySession.InvokeResult.ok(payload)
    } catch (e: Throwable) {
      GatewaySession.InvokeResult.error(
        code = "WATCH_UNAVAILABLE",
        message = "WATCH_UNAVAILABLE: ${e.message}",
      )
    }
  }

  private fun parseNotifyParams(paramsJson: String): WatchNotifyParams {
    val root = json.parseToJsonElement(paramsJson).jsonObject
    val title = root["title"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
    val body = root["body"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
    val promptId = root["promptId"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
    val sessionKey = root["sessionKey"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
    val kind = root["kind"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
    val details = root["details"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
    val expiresAtMs = root["expiresAtMs"]?.jsonPrimitive?.longOrNull
    val risk = root["risk"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }

    val actions = root["actions"]?.jsonArray?.mapNotNull { element ->
      try {
        val obj = element.jsonObject
        val id = obj["id"]?.jsonPrimitive?.contentOrNull?.trim() ?: return@mapNotNull null
        val label = obj["label"]?.jsonPrimitive?.contentOrNull?.trim() ?: return@mapNotNull null
        if (id.isEmpty() || label.isEmpty()) return@mapNotNull null
        val style = obj["style"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
        WatchActionParam(id = id, label = label, style = style)
      } catch (_: Throwable) {
        null
      }
    }

    return WatchNotifyParams(
      title = title,
      body = body,
      promptId = promptId,
      sessionKey = sessionKey,
      kind = kind,
      details = details,
      expiresAtMs = expiresAtMs,
      risk = risk,
      actions = actions,
    )
  }
}
