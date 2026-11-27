package dev.sagron.zerotrustprivacy

import android.app.AppOpsManager
import android.content.Context
import android.content.pm.PackageManager
import java.lang.reflect.InvocationTargetException
import org.lsposed.hiddenapibypass.HiddenApiBypass

/**
 * "Deep mode": which app used the camera, microphone or location, and when.
 *
 * Android keeps this from normal apps. It takes the GET_APP_OPS_STATS
 * permission, which only the system holds, unless a computer grants it once:
 *
 *   adb shell pm grant dev.sagron.zerotrustprivacy android.permission.GET_APP_OPS_STATS
 *
 * Even then the methods that read it are off Android's public list, so they
 * are called by name. The phone test tries each step and reports how far it
 * got, with Android's own words when it refuses:
 *
 *  1. plain: call the method by name.
 *  2. exempted: ask to be let through to the hidden methods, then call again.
 */
class AppOpsReader(private val context: Context) {
    fun read(): Map<String, Any?> {
        val out = HashMap<String, Any?>()
        out["permissionGranted"] =
            context.checkSelfPermission(PERMISSION) == PackageManager.PERMISSION_GRANTED

        val attempts = ArrayList<Map<String, Any?>>()
        var entries: List<Map<String, Any?>>? = null

        try {
            entries = packagesForOps()
            attempts.add(mapOf("step" to "plain", "ok" to true))
        } catch (e: Throwable) {
            attempts.add(mapOf("step" to "plain", "ok" to false, "error" to describe(e)))
        }

        if (entries == null) {
            try {
                val exempted =
                    HiddenApiBypass.addHiddenApiExemptions("Landroid/app/AppOpsManager")
                attempts.add(mapOf("step" to "exemption", "ok" to exempted))
                entries = packagesForOps()
                attempts.add(mapOf("step" to "exempted", "ok" to true))
            } catch (e: Throwable) {
                attempts.add(mapOf("step" to "exempted", "ok" to false, "error" to describe(e)))
            }
        }

        out["attempts"] = attempts
        out["entries"] = entries ?: emptyList<Map<String, Any?>>()
        return out
    }

    /** One row per app and kind of access: the last time it was used. */
    private fun packagesForOps(): List<Map<String, Any?>> {
        val appOps = context.getSystemService(AppOpsManager::class.java)
        val method = AppOpsManager::class.java
            .getMethod("getPackagesForOps", Array<String>::class.java)
        val packages = method.invoke(appOps, OPS) as? List<*> ?: return emptyList()
        val out = ArrayList<Map<String, Any?>>()
        for (packageOps in packages) {
            if (packageOps == null) continue
            val name = call(packageOps, "getPackageName") as? String ?: continue
            val ops = call(packageOps, "getOps") as? List<*> ?: continue
            for (op in ops) {
                if (op == null) continue
                out.add(
                    mapOf(
                        "package" to name,
                        "op" to (call(op, "getOpStr") as? String),
                        "lastAccess" to (callWithFlags(op, "getLastAccessTime") as? Long),
                        "lastReject" to (callWithFlags(op, "getLastRejectTime") as? Long),
                        "running" to (call(op, "isRunning") as? Boolean),
                    ),
                )
            }
        }
        return out
    }

    private fun call(target: Any, name: String): Any? = try {
        target.javaClass.getMethod(name).invoke(target)
    } catch (e: Throwable) {
        null
    }

    private fun callWithFlags(target: Any, name: String): Any? = try {
        target.javaClass.getMethod(name, Int::class.javaPrimitiveType).invoke(target, ALL_FLAGS)
    } catch (e: Throwable) {
        null
    }

    private fun describe(e: Throwable): String {
        // A method called by name wraps what it threw; the cause is the news.
        val cause = if (e is InvocationTargetException) e.targetException ?: e else e
        return "${cause.javaClass.simpleName}: ${cause.message ?: ""}"
    }

    companion object {
        const val PERMISSION = "android.permission.GET_APP_OPS_STATS"

        // AppOpsManager.OP_FLAGS_ALL: the app itself and anything acting for it.
        const val ALL_FLAGS = 31

        val OPS = arrayOf(
            AppOpsManager.OPSTR_CAMERA,
            AppOpsManager.OPSTR_RECORD_AUDIO,
            AppOpsManager.OPSTR_FINE_LOCATION,
            AppOpsManager.OPSTR_COARSE_LOCATION,
            AppOpsManager.OPSTR_READ_CONTACTS,
        )
    }
}
