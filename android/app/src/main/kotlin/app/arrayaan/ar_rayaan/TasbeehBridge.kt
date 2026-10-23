package app.arrayaan.ar_rayaan

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * The hand-off between the service and the Flutter engine, when there is
 * one. [sink] is set while the Dart screen is listening and cleared when it
 * stops or the engine goes away. Only ever touched on the main thread.
 */
object TasbeehBridge {
    var sink: EventChannel.EventSink? = null

    /** The running service, so the app can refresh its notification. */
    var service: TasbeehService? = null

    private val main = Handler(Looper.getMainLooper())

    /** Tells Dart "buttons were pressed, collect them". Any thread. */
    fun ping() {
        main.post {
            try {
                sink?.success(null)
            } catch (e: Exception) {
                // The engine went away; the presses stay pending.
            }
        }
    }
}
