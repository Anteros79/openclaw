package ai.openclaw.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import ai.openclaw.wear.ui.WatchInboxScreen
import ai.openclaw.wear.ui.WatchTheme
import kotlinx.coroutines.launch

class WearMainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val app = application as OpenClawWearApp

    setContent {
      WatchTheme {
        WatchInboxScreen(
          store = app.inboxStore,
          onAction = { action ->
            val draft = app.inboxStore.makeReplyPayload(action)
            app.inboxStore.markReplySending(action.label)
            app.scope.launch {
              val result = app.sender.sendReply(draft)
              app.inboxStore.markReplyResult(
                success = result.success,
                errorMessage = result.errorMessage,
                actionLabel = action.label,
              )
            }
          },
        )
      }
    }
  }
}
