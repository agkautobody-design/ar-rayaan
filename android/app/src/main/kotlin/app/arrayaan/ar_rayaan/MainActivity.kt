package app.arrayaan.ar_rayaan

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Tasbeeh counter: counting with the volume / headset buttons while
        // the screen is off (see TasbeehService).
        MethodChannel(messenger, "app.arrayaan/tasbeeh").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    result.success(
                        startTasbeeh(
                            call.argument<Int>("count") ?: 0,
                            call.argument<Int>("rounds") ?: 0,
                            call.argument<Int>("target") ?: 33,
                        ),
                    )
                }
                "update" -> {
                    TasbeehCounter.setBase(
                        applicationContext,
                        call.argument<Int>("count") ?: 0,
                        call.argument<Int>("rounds") ?: 0,
                        call.argument<Int>("target") ?: 33,
                    )
                    TasbeehBridge.service?.refreshNotification()
                    result.success(null)
                }
                "stop" -> {
                    stopService(Intent(this, TasbeehService::class.java))
                    result.success(null)
                }
                "takePendingDelta" -> {
                    result.success(TasbeehCounter.takePending(applicationContext))
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "app.arrayaan/tasbeeh/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TasbeehBridge.sink = events
                }

                override fun onCancel(arguments: Any?) {
                    TasbeehBridge.sink = null
                }
            },
        )
    }

    private fun startTasbeeh(count: Int, rounds: Int, target: Int): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                // Without it the service still counts, but its notification
                // stays hidden.
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7301)
            }
            TasbeehCounter.setBase(applicationContext, count, rounds, target)
            val intent = Intent(this, TasbeehService::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (e: Exception) {
            false
        }
    }
}
