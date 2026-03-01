package ai.openclaw.wear

import kotlinx.serialization.Serializable

@Serializable
data class WatchPromptAction(
  val id: String,
  val label: String,
  val style: String? = null,
)

@Serializable
data class WatchNotifyPayload(
  val type: String,
  val id: String? = null,
  val title: String = "OpenClaw",
  val body: String = "",
  val sentAtMs: Long? = null,
  val promptId: String? = null,
  val sessionKey: String? = null,
  val kind: String? = null,
  val details: String? = null,
  val expiresAtMs: Long? = null,
  val risk: String? = null,
  val actions: List<WatchPromptAction>? = null,
)

@Serializable
data class WatchReplyPayload(
  val type: String = "watch.reply",
  val replyId: String,
  val promptId: String,
  val actionId: String,
  val actionLabel: String? = null,
  val sessionKey: String? = null,
  val note: String? = null,
  val sentAtMs: Long,
)

@Serializable
data class PersistedInboxState(
  val title: String = "OpenClaw",
  val body: String = "Waiting for messages from your phone.",
  val transport: String = "none",
  val updatedAtMs: Long? = null,
  val lastDeliveryKey: String? = null,
  val promptId: String? = null,
  val sessionKey: String? = null,
  val kind: String? = null,
  val details: String? = null,
  val expiresAtMs: Long? = null,
  val risk: String? = null,
  val actions: List<WatchPromptAction> = emptyList(),
  val replyStatusText: String? = null,
  val replyStatusAtMs: Long? = null,
)
