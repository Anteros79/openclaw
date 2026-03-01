package ai.openclaw.wear.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import ai.openclaw.wear.WatchInboxStore
import ai.openclaw.wear.WatchPromptAction
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun WatchInboxScreen(
  store: WatchInboxStore,
  onAction: (WatchPromptAction) -> Unit,
) {
  val title by store.title.collectAsState()
  val body by store.body.collectAsState()
  val details by store.details.collectAsState()
  val actions by store.actions.collectAsState()
  val isReplySending by store.isReplySending.collectAsState()
  val replyStatusText by store.replyStatusText.collectAsState()
  val updatedAtMs by store.updatedAtMs.collectAsState()

  val listState = rememberScalingLazyListState()

  ScalingLazyColumn(
    modifier = Modifier.fillMaxSize(),
    state = listState,
  ) {
    // Title
    item {
      Text(
        text = title,
        style = MaterialTheme.typography.title3,
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 12.dp),
      )
    }

    // Body
    item {
      Text(
        text = body,
        style = MaterialTheme.typography.body1,
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 12.dp, vertical = 4.dp),
      )
    }

    // Details
    if (!details.isNullOrBlank()) {
      item {
        Text(
          text = details.orEmpty(),
          style = MaterialTheme.typography.caption2,
          color = MaterialTheme.colors.onSurfaceVariant,
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        )
      }
    }

    // Action buttons
    items(actions.size) { index ->
      val action = actions[index]
      val isDestructive = action.style?.trim()?.lowercase() == "destructive"
      Chip(
        onClick = { onAction(action) },
        enabled = !isReplySending,
        label = {
          Text(
            text = action.label,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
          )
        },
        colors = if (isDestructive) {
          ChipDefaults.secondaryChipColors()
        } else {
          ChipDefaults.primaryChipColors()
        },
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 12.dp, vertical = 2.dp),
      )
    }

    // Reply status
    if (!replyStatusText.isNullOrBlank()) {
      item {
        Text(
          text = replyStatusText.orEmpty(),
          style = MaterialTheme.typography.caption2,
          color = MaterialTheme.colors.onSurfaceVariant,
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp),
        )
      }
    }

    // Updated timestamp
    if (updatedAtMs != null) {
      item {
        val formatted = formatTime(updatedAtMs!!)
        Text(
          text = "Updated $formatted",
          style = MaterialTheme.typography.caption2,
          color = MaterialTheme.colors.onSurfaceVariant,
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp),
        )
      }
    }
  }
}

private fun formatTime(epochMs: Long): String {
  val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
  return sdf.format(Date(epochMs))
}
