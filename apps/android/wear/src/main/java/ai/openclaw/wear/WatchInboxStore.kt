package ai.openclaw.wear

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.util.UUID

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "watch_inbox")

private val KEY_INBOX_STATE = stringPreferencesKey("inbox_state_v1")

class WatchInboxStore(
  private val context: Context,
  private val scope: CoroutineScope,
) {
  private val json = Json { ignoreUnknownKeys = true }

  private val _title = MutableStateFlow("OpenClaw")
  val title: StateFlow<String> = _title.asStateFlow()

  private val _body = MutableStateFlow("Waiting for messages from your phone.")
  val body: StateFlow<String> = _body.asStateFlow()

  private val _transport = MutableStateFlow("none")
  val transport: StateFlow<String> = _transport.asStateFlow()

  private val _updatedAtMs = MutableStateFlow<Long?>(null)
  val updatedAtMs: StateFlow<Long?> = _updatedAtMs.asStateFlow()

  private val _promptId = MutableStateFlow<String?>(null)
  val promptId: StateFlow<String?> = _promptId.asStateFlow()

  private val _sessionKey = MutableStateFlow<String?>(null)
  val sessionKey: StateFlow<String?> = _sessionKey.asStateFlow()

  private val _kind = MutableStateFlow<String?>(null)
  val kind: StateFlow<String?> = _kind.asStateFlow()

  private val _details = MutableStateFlow<String?>(null)
  val details: StateFlow<String?> = _details.asStateFlow()

  private val _expiresAtMs = MutableStateFlow<Long?>(null)
  val expiresAtMs: StateFlow<Long?> = _expiresAtMs.asStateFlow()

  private val _risk = MutableStateFlow<String?>(null)
  val risk: StateFlow<String?> = _risk.asStateFlow()

  private val _actions = MutableStateFlow<List<WatchPromptAction>>(emptyList())
  val actions: StateFlow<List<WatchPromptAction>> = _actions.asStateFlow()

  private val _replyStatusText = MutableStateFlow<String?>(null)
  val replyStatusText: StateFlow<String?> = _replyStatusText.asStateFlow()

  private val _isReplySending = MutableStateFlow(false)
  val isReplySending: StateFlow<Boolean> = _isReplySending.asStateFlow()

  private var lastDeliveryKey: String? = null

  init {
    scope.launch { restorePersistedState() }
  }

  fun consume(payload: WatchNotifyPayload, transport: String) {
    val messageId = payload.id?.trim()?.ifEmpty { null }
    val deliveryKey = deliveryKey(messageId, payload.title, payload.body, payload.sentAtMs)
    if (deliveryKey == lastDeliveryKey) return

    val normalizedTitle = payload.title.ifBlank { "OpenClaw" }
    _title.value = normalizedTitle
    _body.value = payload.body
    _transport.value = transport
    _updatedAtMs.value = System.currentTimeMillis()
    _promptId.value = payload.promptId?.trim()?.ifEmpty { null }
    _sessionKey.value = payload.sessionKey?.trim()?.ifEmpty { null }
    _kind.value = payload.kind?.trim()?.ifEmpty { null }
    _details.value = payload.details?.trim()?.ifEmpty { null }
    _expiresAtMs.value = payload.expiresAtMs
    _risk.value = payload.risk?.trim()?.ifEmpty { null }
    _actions.value = payload.actions.orEmpty()
    lastDeliveryKey = deliveryKey
    _replyStatusText.value = null
    _isReplySending.value = false

    scope.launch { persistState() }
  }

  fun makeReplyPayload(action: WatchPromptAction): WatchReplyPayload {
    val prompt = _promptId.value?.trim()?.ifEmpty { null } ?: "unknown"
    return WatchReplyPayload(
      replyId = UUID.randomUUID().toString(),
      promptId = prompt,
      actionId = action.id,
      actionLabel = action.label,
      sessionKey = _sessionKey.value,
      note = null,
      sentAtMs = System.currentTimeMillis(),
    )
  }

  fun markReplySending(actionLabel: String) {
    _isReplySending.value = true
    _replyStatusText.value = "Sending $actionLabel\u2026"
    scope.launch { persistState() }
  }

  fun markReplyResult(success: Boolean, errorMessage: String?, actionLabel: String) {
    _isReplySending.value = false
    _replyStatusText.value = if (errorMessage != null) {
      "Failed: $errorMessage"
    } else if (success) {
      "$actionLabel: sent"
    } else {
      "$actionLabel: queued"
    }
    scope.launch { persistState() }
  }

  private fun deliveryKey(messageId: String?, title: String, body: String, sentAtMs: Long?): String {
    if (!messageId.isNullOrEmpty()) return "id:$messageId"
    return "content:$title|$body|${sentAtMs ?: 0}"
  }

  private suspend fun restorePersistedState() {
    try {
      val prefs = context.dataStore.data.first()
      val raw = prefs[KEY_INBOX_STATE] ?: return
      val state = json.decodeFromString<PersistedInboxState>(raw)
      _title.value = state.title
      _body.value = state.body
      _transport.value = state.transport
      _updatedAtMs.value = state.updatedAtMs
      lastDeliveryKey = state.lastDeliveryKey
      _promptId.value = state.promptId
      _sessionKey.value = state.sessionKey
      _kind.value = state.kind
      _details.value = state.details
      _expiresAtMs.value = state.expiresAtMs
      _risk.value = state.risk
      _actions.value = state.actions
      _replyStatusText.value = state.replyStatusText
    } catch (_: Throwable) {
      // ignore corrupt persisted state
    }
  }

  private suspend fun persistState() {
    val state = PersistedInboxState(
      title = _title.value,
      body = _body.value,
      transport = _transport.value,
      updatedAtMs = _updatedAtMs.value,
      lastDeliveryKey = lastDeliveryKey,
      promptId = _promptId.value,
      sessionKey = _sessionKey.value,
      kind = _kind.value,
      details = _details.value,
      expiresAtMs = _expiresAtMs.value,
      risk = _risk.value,
      actions = _actions.value,
      replyStatusText = _replyStatusText.value,
      replyStatusAtMs = System.currentTimeMillis(),
    )
    try {
      context.dataStore.edit { prefs ->
        prefs[KEY_INBOX_STATE] = json.encodeToString(PersistedInboxState.serializer(), state)
      }
    } catch (_: Throwable) {
      // ignore
    }
  }
}
