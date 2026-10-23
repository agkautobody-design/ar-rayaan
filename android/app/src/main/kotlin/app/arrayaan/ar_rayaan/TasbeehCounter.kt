package app.arrayaan.ar_rayaan

import android.content.Context

/**
 * The counter as the Android service sees it, kept in its own preferences
 * file so it survives the Flutter engine being gone.
 *
 * The Dart screen is always the owner of the "real" count. Presses made
 * while the screen is off are added to [pending]; Dart collects them with
 * [takePending] and applies the same steps. This copy (count, rounds,
 * target) only exists so the notification can show the right number, so it
 * is always "what Dart last sent" plus whatever is still pending.
 *
 * Same rules as lib/features/tasbeeh/domain/tasbeeh_counter.dart: the count
 * runs 0..target-1, reaching the target starts the next round at 0.
 */
object TasbeehCounter {
    private const val PREFS = "ar_tasbeeh_native"
    private const val MAX_TARGET = 100000
    private const val MAX_ROUNDS = 999999
    private const val MAX_PENDING = 1000000

    data class Snapshot(
        val count: Int,
        val rounds: Int,
        val target: Int,
        val reachedTarget: Boolean,
    )

    private class Pos(var count: Int, var rounds: Int, val target: Int) {
        /** +1. Returns true when this closed a round. */
        fun inc(): Boolean {
            val next = count + 1
            if (next >= target) {
                if (rounds >= MAX_ROUNDS) return false
                count = 0
                rounds += 1
                return true
            }
            count = next
            return false
        }

        /** -1, across a round boundary, never below zero. */
        fun dec() {
            if (count > 0) {
                count -= 1
            } else if (rounds > 0) {
                count = target - 1
                rounds -= 1
            }
        }
    }

    private fun prefs(c: Context) =
        c.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(c: Context): Pos {
        val p = prefs(c)
        val target = p.getInt("target", 33).coerceIn(1, MAX_TARGET)
        return Pos(
            p.getInt("count", 0).coerceIn(0, target - 1),
            p.getInt("rounds", 0).coerceIn(0, MAX_ROUNDS),
            target,
        )
    }

    private fun save(c: Context, pos: Pos, pending: Int) {
        prefs(c).edit()
            .putInt("count", pos.count)
            .putInt("rounds", pos.rounds)
            .putInt("target", pos.target)
            .putInt("pending", pending)
            .apply()
    }

    /**
     * Dart sends the counter as it knows it (without the pending presses).
     * The copy kept here is that plus the pending presses.
     */
    @Synchronized
    fun setBase(c: Context, count: Int, rounds: Int, target: Int): Snapshot {
        val t = target.coerceIn(1, MAX_TARGET)
        val pos = Pos(count.coerceIn(0, t - 1), rounds.coerceIn(0, MAX_ROUNDS), t)
        val pending = prefs(c).getInt("pending", 0)
        var i = 0
        while (i < Math.abs(pending)) {
            if (pending > 0) pos.inc() else pos.dec()
            i += 1
        }
        save(c, pos, pending)
        return Snapshot(pos.count, pos.rounds, pos.target, false)
    }

    /** One button press: +1 or -1. Safe to call from any thread. */
    @Synchronized
    fun press(c: Context, delta: Int): Snapshot {
        val pos = load(c)
        var reached = false
        if (delta > 0) reached = pos.inc() else pos.dec()
        val pending = (prefs(c).getInt("pending", 0) + (if (delta > 0) 1 else -1))
            .coerceIn(-MAX_PENDING, MAX_PENDING)
        save(c, pos, pending)
        return Snapshot(pos.count, pos.rounds, pos.target, reached)
    }

    @Synchronized
    fun snapshot(c: Context): Snapshot {
        val pos = load(c)
        return Snapshot(pos.count, pos.rounds, pos.target, false)
    }

    /** Net presses since the last call; reading clears them. */
    @Synchronized
    fun takePending(c: Context): Int {
        val p = prefs(c)
        val d = p.getInt("pending", 0)
        if (d != 0) p.edit().putInt("pending", 0).apply()
        return d
    }
}
