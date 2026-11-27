package dev.sagron.zerotrustprivacy

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val probe = DeviceProbe(applicationContext)
        val appOps = AppOpsReader(applicationContext)
        // Read by lib/probe/device_probe.dart. Everything that walks the app
        // list runs off the main thread, so the screen never waits for it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zt_privacy/probe")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "apps" -> background(result) { probe.apps() }
                    "device" -> background(result) { probe.device() }
                    "specialAccess" -> background(result) { probe.specialAccess() }
                    "specialAccessModes" -> {
                        val requests =
                            call.argument<List<Map<String, Any?>>>("requests") ?: emptyList()
                        background(result) { probe.specialAccessModes(requests) }
                    }
                    "usage" -> background(result) { probe.usage() }
                    "appOps" -> background(result) { appOps.read() }
                    "saveToDownloads" -> {
                        val name = call.argument<String>("name") ?: "zt-privacy.txt"
                        val text = call.argument<String>("text") ?: ""
                        background(result) { probe.saveToDownloads(name, text) }
                    }
                    "openSettings" -> result.success(
                        openSettings(
                            call.argument<String>("screen") ?: "",
                            call.argument<String>("package"),
                        ),
                    )
                    "shareText" -> result.success(
                        shareText(
                            call.argument<String>("subject") ?: "",
                            call.argument<String>("text") ?: "",
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        thread {
            val outcome = runCatching(work)
            runOnUiThread {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("probe", it.toString(), null) },
                )
            }
        }
    }

    // Opens a system screen. The answer says whether Android let us, which
    // is itself one of the things the phone test records.
    private fun openSettings(screen: String, packageName: String?): Map<String, Any?> {
        val intent = when (screen) {
            "usageAccess" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            "privacy" -> Intent(Settings.ACTION_PRIVACY_SETTINGS)
            // Android's own Privacy dashboard. Not a public action, so it may
            // be refused; the test shows whether it opens.
            "privacyDashboard" -> Intent("android.intent.action.REVIEW_PERMISSION_USAGE")
            "permissionManager" -> Intent("android.intent.action.MANAGE_PERMISSIONS")
            "developer" -> Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            "appDetails" -> Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName ?: this.packageName, null),
            )
            else -> return mapOf("ok" to false, "error" to "unknown screen: $screen")
        }
        return try {
            startActivity(intent)
            mapOf("ok" to true)
        } catch (e: ActivityNotFoundException) {
            mapOf("ok" to false, "error" to "ActivityNotFoundException: ${e.message}")
        } catch (e: SecurityException) {
            mapOf("ok" to false, "error" to "SecurityException: ${e.message}")
        }
    }

    private fun shareText(subject: String, text: String): Map<String, Any?> {
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_SUBJECT, subject)
            .putExtra(Intent.EXTRA_TEXT, text)
        return try {
            startActivity(Intent.createChooser(send, subject))
            mapOf("ok" to true)
        } catch (e: RuntimeException) {
            // Also covers a text too large to hand to another app.
            mapOf("ok" to false, "error" to "${e.javaClass.simpleName}: ${e.message}")
        }
    }
}
