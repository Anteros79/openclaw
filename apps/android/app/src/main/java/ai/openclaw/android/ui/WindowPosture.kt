package ai.openclaw.android.ui

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.WindowLayoutInfo
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map

sealed class WindowPosture {
  data object Normal : WindowPosture()
  data object Flat : WindowPosture()
  data class Tabletop(val hingeRatio: Float) : WindowPosture()
}

enum class AppWidthClass { Compact, Medium, Expanded }

@Composable
fun rememberWindowPosture(): State<WindowPosture> {
  val context = LocalContext.current
  val activity = context as? Activity
  val postureFlow = remember(activity) {
    if (activity == null) {
      flowOf(WindowPosture.Normal)
    } else {
      WindowInfoTracker.getOrCreate(activity)
        .windowLayoutInfo(activity)
        .map { info -> classifyPosture(info) }
    }
  }
  return postureFlow.collectAsState(initial = WindowPosture.Normal)
}

@Composable
fun rememberAppWidthClass(): AppWidthClass {
  val config = LocalConfiguration.current
  val widthDp = config.screenWidthDp
  return when {
    widthDp >= 840 -> AppWidthClass.Expanded
    widthDp >= 600 -> AppWidthClass.Medium
    else -> AppWidthClass.Compact
  }
}

private fun classifyPosture(info: WindowLayoutInfo): WindowPosture {
  val fold = info.displayFeatures
    .filterIsInstance<FoldingFeature>()
    .firstOrNull()
    ?: return WindowPosture.Normal

  return when {
    fold.state == FoldingFeature.State.HALF_OPENED &&
      fold.orientation == FoldingFeature.Orientation.HORIZONTAL ->
      WindowPosture.Tabletop(hingeRatio = 0.5f)
    fold.state == FoldingFeature.State.FLAT ->
      WindowPosture.Flat
    else -> WindowPosture.Normal
  }
}
