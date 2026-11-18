package com.iarash.planact

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var notificationSettingsResult: MethodChannel.Result? = null
    private val notificationSettingsRequestCode = 4102
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SmsBackgroundRuntime.bind(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        SmsDetectionNotifications.recordTap(applicationContext, intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/sms-notifications")
            .setMethodCallHandler { call, result -> SmsDetectionNotifications.handle(this, call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/alarms")
            .setMethodCallHandler { call, result -> AlarmBridge.handle(applicationContext, call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/reminder-settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "openNotificationSettings") {
                    result.notImplemented()
                } else if (notificationSettingsResult != null) {
                    result.error("settings_busy", "Notification settings are already open", null)
                } else {
                    notificationSettingsResult = result
                    try {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        startActivityForResult(intent, notificationSettingsRequestCode)
                    } catch (_: Exception) {
                        try {
                            startActivityForResult(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:$packageName")),
                                notificationSettingsRequestCode
                            )
                        } catch (_: Exception) {
                            notificationSettingsResult = null
                            result.error("settings_unavailable", "Notification settings are unavailable", null)
                        }
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/sms")
            .setMethodCallHandler { call, result -> SmsBridge.configureMethods(this, call, result) }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/sms/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) { SmsBridge.attach(events) }
                override fun onCancel(arguments: Any?) { }
            })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == notificationSettingsRequestCode) {
            val result = notificationSettingsResult
            notificationSettingsResult = null
            result?.success(null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        SmsDetectionNotifications.recordTap(applicationContext, intent)
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, "planact/sms-notifications")
                .invokeMethod("tapAvailable", null)
        }
    }

    override fun onDestroy() {
        flutterEngine?.let { SmsBackgroundRuntime.detach(it.dartExecutor.binaryMessenger) }
        SmsDetectionNotifications.detach()
        SmsBridge.onActivityDestroyed(this)
        notificationSettingsResult?.error("activity_destroyed", "Activity was closed", null)
        notificationSettingsResult = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        SmsBridge.onRequestPermissionsResult(this, requestCode)
        if (requestCode == SmsDetectionNotifications.PERMISSION_REQUEST) {
            SmsDetectionNotifications.permissionFinished(this)
        }
    }
}
