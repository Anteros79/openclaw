package ai.openclaw.wear

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class OpenClawWearApp : Application() {

  val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  lateinit var inboxStore: WatchInboxStore
    private set
  lateinit var sender: WatchDataLayerSender
    private set

  override fun onCreate() {
    super.onCreate()
    inboxStore = WatchInboxStore(context = this, scope = scope)
    sender = WatchDataLayerSender(context = this)
    createNotificationChannel()
  }

  fun onNotifyReceived(payload: WatchNotifyPayload, transport: String) {
    scope.launch {
      inboxStore.consume(payload, transport)
      postLocalNotification(payload)
      playHaptic(payload.risk)
    }
  }

  private fun createNotificationChannel() {
    val channel = NotificationChannel(
      CHANNEL_ID,
      "OpenClaw Notifications",
      NotificationManager.IMPORTANCE_HIGH,
    ).apply {
      description = "Notifications from the OpenClaw agent"
    }
    val manager = getSystemService(NotificationManager::class.java)
    manager.createNotificationChannel(channel)
  }

  private fun postLocalNotification(payload: WatchNotifyPayload) {
    val title = payload.title.ifBlank { "OpenClaw" }
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(android.R.drawable.ic_dialog_info)
      .setContentTitle(title)
      .setContentText(payload.body)
      .setPriority(NotificationCompat.PRIORITY_HIGH)
      .setAutoCancel(true)
      .build()

    val notificationId = (payload.id ?: payload.body).hashCode()
    val manager = getSystemService(NotificationManager::class.java)
    manager.notify(notificationId, notification)
  }

  private fun playHaptic(risk: String?) {
    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val manager = getSystemService(VibratorManager::class.java)
      manager.defaultVibrator
    } else {
      @Suppress("DEPRECATION")
      getSystemService(Vibrator::class.java)
    }

    val effect = when (risk?.trim()?.lowercase()) {
      "high" -> VibrationEffect.createWaveform(longArrayOf(0, 100, 80, 100, 80, 200), -1)
      "medium" -> VibrationEffect.createWaveform(longArrayOf(0, 100, 80, 150), -1)
      else -> VibrationEffect.createOneShot(80, VibrationEffect.DEFAULT_AMPLITUDE)
    }
    vibrator.vibrate(effect)
  }

  companion object {
    private const val CHANNEL_ID = "openclaw_watch"
  }
}
