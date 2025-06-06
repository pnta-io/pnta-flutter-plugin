package io.pnta.pnta_flutter

import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel.Result

object PermissionHandler {
    private const val REQUEST_CODE = 1001
    private var permissionResult: Result? = null

    fun requestNotificationPermission(activity: Activity?, result: Result) {
        if (Build.VERSION.SDK_INT >= 33) {
            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity is null", null)
                return
            }
            if (ContextCompat.checkSelfPermission(activity, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
            } else {
                permissionResult = result
                ActivityCompat.requestPermissions(activity, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
            }
        } else {
            // Permission is automatically granted on older versions
            result.success(true)
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == REQUEST_CODE) {
            permissionResult?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            permissionResult = null
            return true
        }
        return false
    }

    fun cleanup() {
        permissionResult = null
    }
} 