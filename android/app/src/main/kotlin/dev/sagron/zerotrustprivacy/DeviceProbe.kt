package dev.sagron.zerotrustprivacy

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Process
import android.provider.MediaStore
import android.provider.Settings
import android.provider.Telephony
import android.security.advancedprotection.AdvancedProtectionManager
import android.telecom.TelecomManager
import android.view.accessibility.AccessibilityManager
import android.view.inputmethod.InputMethodManager

/**
 * Reads what a normal app is allowed to know about the phone: the installed
 * apps and their permissions, who holds powerful special access, and the
 * settings a privacy check cares about.
 *
 * Nothing here needs root. Every single read is wrapped, and a refusal is
 * reported as data instead of failing the whole run: which reads Android (and
 * GrapheneOS) allows is exactly what the phone test is there to find out.
 *
 * Everything returned is made of the plain types Flutter's message codec
 * carries (maps, lists, strings, numbers, booleans).
 */
class DeviceProbe(private val context: Context) {
    private val pm: PackageManager get() = context.packageManager

    // ---- Installed apps -------------------------------------------------

    fun apps(): List<Map<String, Any?>> {
        val packages = if (Build.VERSION.SDK_INT >= 33) {
            pm.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        }
        return packages.map { describe(it) }
    }

    private fun describe(info: PackageInfo): Map<String, Any?> {
        val app: ApplicationInfo? = info.applicationInfo
        val requested: List<String> = info.requestedPermissions?.toList() ?: emptyList()
        val flags: IntArray? = info.requestedPermissionsFlags
        val granted: List<Boolean> = requested.indices.map { i ->
            flags != null && i < flags.size &&
                (flags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0
        }
        val label = try {
            if (app != null) pm.getApplicationLabel(app).toString() else info.packageName
        } catch (e: RuntimeException) {
            info.packageName
        }
        return mapOf(
            "package" to info.packageName,
            "label" to label,
            "system" to (app != null && (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
            "enabled" to (app?.enabled ?: true),
            "uid" to (app?.uid ?: -1),
            "targetSdk" to (app?.targetSdkVersion ?: 0),
            "firstInstall" to info.firstInstallTime,
            "lastUpdate" to info.lastUpdateTime,
            "installer" to installerOf(info.packageName),
            "sourceDir" to app?.sourceDir,
            "splitDirs" to (app?.splitSourceDirs?.toList() ?: emptyList<String>()),
            "requested" to requested,
            "granted" to granted,
            // GrapheneOS can take the network away from an app (its Network
            // switch is the INTERNET permission made revocable) and has a
            // Sensors switch apps do not declare. Whether another app can see
            // either is one of the open questions of the phone test.
            "internetGranted" to isGranted(Manifest.permission.INTERNET, info.packageName),
            "otherSensorsGranted" to isGranted(OTHER_SENSORS, info.packageName),
        )
    }

    private fun isGranted(permission: String, packageName: String): Boolean =
        pm.checkPermission(permission, packageName) == PackageManager.PERMISSION_GRANTED

    private fun installerOf(packageName: String): String? = try {
        if (Build.VERSION.SDK_INT >= 30) {
            pm.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            pm.getInstallerPackageName(packageName)
        }
    } catch (e: Exception) {
        null
    }

    // ---- Device settings ------------------------------------------------

    fun device(): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        probe(out, "build.manufacturer") { Build.MANUFACTURER }
        probe(out, "build.model") { Build.MODEL }
        probe(out, "build.device") { Build.DEVICE }
        probe(out, "build.sdk") { Build.VERSION.SDK_INT }
        probe(out, "build.release") { Build.VERSION.RELEASE }
        probe(out, "build.securityPatch") { Build.VERSION.SECURITY_PATCH }
        probe(out, "build.display") { Build.DISPLAY }
        probe(out, "user.id") { Process.myUid() / 100000 }

        // GrapheneOS, told by what only it has.
        probe(out, "grapheneos.otherSensorsPermission") {
            pm.getPermissionInfo(OTHER_SENSORS, 0).name
        }
        probe(out, "grapheneos.appStore") { pm.getPackageInfo("app.grapheneos.apps", 0).packageName }
        probe(out, "grapheneos.vanadium") { pm.getPackageInfo("app.vanadium.browser", 0).packageName }

        probe(out, "lock.deviceSecure") {
            context.getSystemService(KeyguardManager::class.java).isDeviceSecure
        }
        probe(out, "encryption.status") {
            when (
                val status =
                    context.getSystemService(DevicePolicyManager::class.java).storageEncryptionStatus
            ) {
                DevicePolicyManager.ENCRYPTION_STATUS_UNSUPPORTED -> "unsupported"
                DevicePolicyManager.ENCRYPTION_STATUS_INACTIVE -> "inactive"
                DevicePolicyManager.ENCRYPTION_STATUS_ACTIVATING -> "activating"
                DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE -> "active"
                DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_DEFAULT_KEY -> "active, default key"
                DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER -> "active, per user"
                else -> "unknown ($status)"
            }
        }

        probe(out, "network.privateDnsActive") { activeLink()?.isPrivateDnsActive }
        probe(out, "network.privateDnsServer") { activeLink()?.privateDnsServerName }
        probe(out, "network.vpnActive") {
            activeCapabilities()?.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        }

        probe(out, "advancedProtection.enabled") {
            if (Build.VERSION.SDK_INT >= 36) {
                context.getSystemService(AdvancedProtectionManager::class.java)
                    ?.isAdvancedProtectionEnabled
            } else {
                "needs Android 16"
            }
        }

        for (key in GLOBAL_SETTINGS) {
            probe(out, "global.$key") { Settings.Global.getString(context.contentResolver, key) }
        }
        for (key in SECURE_SETTINGS) {
            probe(out, "secure.$key") { Settings.Secure.getString(context.contentResolver, key) }
        }
        return out
    }

    private fun activeLink() = context.getSystemService(ConnectivityManager::class.java).let {
        it.getLinkProperties(it.activeNetwork)
    }

    private fun activeCapabilities() =
        context.getSystemService(ConnectivityManager::class.java).let {
            it.getNetworkCapabilities(it.activeNetwork)
        }

    /** One read: its value as text, or the reason Android refused it. */
    private fun probe(out: MutableList<Map<String, Any?>>, id: String, read: () -> Any?) {
        val entry = HashMap<String, Any?>()
        entry["id"] = id
        try {
            entry["value"] = read()?.toString()
            entry["ok"] = true
        } catch (e: Throwable) {
            entry["ok"] = false
            entry["error"] = "${e.javaClass.simpleName}: ${e.message ?: ""}"
        }
        out.add(entry)
    }

    // ---- Special access -------------------------------------------------

    fun specialAccess(): Map<String, Any?> {
        val out = HashMap<String, Any?>()
        list(out, "accessibilityServices") {
            context.getSystemService(AccessibilityManager::class.java)
                .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                .map { it.id }
        }
        list(out, "deviceAdmins") {
            context.getSystemService(DevicePolicyManager::class.java).activeAdmins
                ?.map { it.flattenToShortString() } ?: emptyList()
        }
        list(out, "notificationListeners") {
            Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                ?.split(':')?.filter { it.isNotEmpty() } ?: emptyList()
        }
        list(out, "keyboards") {
            context.getSystemService(InputMethodManager::class.java).enabledInputMethodList
                .map { it.id }
        }
        list(out, "vpnApps") {
            pm.queryIntentServices(Intent("android.net.VpnService"), 0)
                .map { it.serviceInfo.packageName }.distinct()
        }
        list(out, "defaultSms") { listOfNotNull(Telephony.Sms.getDefaultSmsPackage(context)) }
        list(out, "defaultDialer") {
            listOfNotNull(context.getSystemService(TelecomManager::class.java).defaultDialerPackage)
        }
        list(out, "defaultBrowser") {
            listOfNotNull(
                pm.resolveActivity(
                    Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")),
                    PackageManager.MATCH_DEFAULT_ONLY,
                )?.activityInfo?.packageName,
            )
        }
        list(out, "defaultHome") {
            listOfNotNull(
                pm.resolveActivity(
                    Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
                    PackageManager.MATCH_DEFAULT_ONLY,
                )?.activityInfo?.packageName,
            )
        }
        return out
    }

    private fun list(out: MutableMap<String, Any?>, id: String, read: () -> List<String>) {
        out[id] = try {
            mapOf("ok" to true, "items" to read())
        } catch (e: Throwable) {
            mapOf(
                "ok" to false,
                "items" to emptyList<String>(),
                "error" to "${e.javaClass.simpleName}: ${e.message ?: ""}",
            )
        }
    }

    /**
     * Asks Android whether [packageName] is actually allowed the special
     * access behind [op] (display over other apps, all files, and so on).
     * These are not ordinary permissions, so the granted flag in the app
     * list does not answer it. Returns the mode, or the refusal.
     */
    fun specialAccessMode(op: String, uid: Int, packageName: String): String = try {
        val appOps = context.getSystemService(AppOpsManager::class.java)
        @Suppress("DEPRECATION")
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            appOps.unsafeCheckOpNoThrow(op, uid, packageName)
        } else {
            appOps.checkOpNoThrow(op, uid, packageName)
        }
        when (mode) {
            AppOpsManager.MODE_ALLOWED -> "allowed"
            AppOpsManager.MODE_IGNORED -> "ignored"
            AppOpsManager.MODE_ERRORED -> "errored"
            AppOpsManager.MODE_DEFAULT -> "default"
            AppOpsManager.MODE_FOREGROUND -> "foreground"
            else -> "mode $mode"
        }
    } catch (e: Throwable) {
        "${e.javaClass.simpleName}: ${e.message ?: ""}"
    }

    /** [specialAccessMode] for many apps in one call: op, uid, package. */
    fun specialAccessModes(requests: List<Map<String, Any?>>): List<String> = requests.map {
        specialAccessMode(
            it["op"] as? String ?: "",
            (it["uid"] as? Number)?.toInt() ?: -1,
            it["package"] as? String ?: "",
        )
    }

    // ---- Usage access ---------------------------------------------------

    fun usage(): Map<String, Any?> {
        val out = HashMap<String, Any?>()
        val granted = specialAccessMode(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        ) == "allowed"
        out["granted"] = granted
        if (!granted) return out

        val now = System.currentTimeMillis()
        val from = now - 90L * 24 * 60 * 60 * 1000
        try {
            val stats = context.getSystemService(UsageStatsManager::class.java)
                .queryAndAggregateUsageStats(from, now)
            out["apps"] = stats.values.map {
                mapOf(
                    "package" to it.packageName,
                    "lastUsed" to it.lastTimeUsed,
                    "foregroundMs" to it.totalTimeInForeground,
                )
            }
        } catch (e: Throwable) {
            out["appsError"] = "${e.javaClass.simpleName}: ${e.message ?: ""}"
        }
        out["wifi"] = dataUse(NetworkCapabilities.TRANSPORT_WIFI, from, now)
        out["mobile"] = dataUse(NetworkCapabilities.TRANSPORT_CELLULAR, from, now)
        return out
    }

    /** Bytes moved per app (by uid) on Wi-Fi or mobile data. */
    private fun dataUse(transport: Int, from: Long, to: Long): Map<String, Any?> = try {
        @Suppress("DEPRECATION")
        val type = if (transport == NetworkCapabilities.TRANSPORT_WIFI) {
            ConnectivityManager.TYPE_WIFI
        } else {
            ConnectivityManager.TYPE_MOBILE
        }
        val totals = HashMap<Int, Long>()
        val buckets = context.getSystemService(NetworkStatsManager::class.java)
            .querySummary(type, null, from, to)
        try {
            val bucket = NetworkStats.Bucket()
            while (buckets.hasNextBucket()) {
                buckets.getNextBucket(bucket)
                totals[bucket.uid] = (totals[bucket.uid] ?: 0L) + bucket.rxBytes + bucket.txBytes
            }
        } finally {
            buckets.close()
        }
        mapOf(
            "ok" to true,
            "uids" to totals.keys.toList(),
            "bytes" to totals.values.toList(),
        )
    } catch (e: Throwable) {
        mapOf("ok" to false, "error" to "${e.javaClass.simpleName}: ${e.message ?: ""}")
    }

    // ---- Saving the results --------------------------------------------

    /** Writes a text file into the phone's Downloads folder. */
    fun saveToDownloads(name: String, text: String): String {
        if (Build.VERSION.SDK_INT < 29) {
            throw UnsupportedOperationException("Saving to Downloads needs Android 10")
        }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, "text/plain")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Android gave no place to save the file")
        val stream = resolver.openOutputStream(uri)
            ?: throw IllegalStateException("Android could not open the file")
        stream.use { it.write(text.toByteArray(Charsets.UTF_8)) }
        return uri.toString()
    }

    companion object {
        const val OTHER_SENSORS = "android.permission.OTHER_SENSORS"

        // Read as text, so a missing key is an empty answer, not a failure.
        val GLOBAL_SETTINGS = listOf(
            "adb_enabled",
            "adb_wifi_enabled",
            "development_settings_enabled",
            "private_dns_mode",
            "private_dns_specifier",
            "airplane_mode_on",
            "wifi_on",
            "bluetooth_on",
            "wifi_scan_always_enabled",
            "ble_scan_always_enabled",
            "auto_time",
            "package_verifier_user_consent",
            "install_non_market_apps",
        )
        val SECURE_SETTINGS = listOf(
            "location_mode",
            "lock_screen_show_notifications",
            "lock_screen_allow_private_notifications",
            "lockdown_in_power_menu",
            "always_on_vpn_app",
            "always_on_vpn_lockdown",
            "default_input_method",
            "enabled_accessibility_services",
            "enabled_notification_listeners",
            "autofill_service",
            "credential_service",
            "voice_interaction_service",
            "assistant",
            "backup_enabled",
            "install_non_market_apps",
            "nfc_payment_default_component",
        )
    }
}
