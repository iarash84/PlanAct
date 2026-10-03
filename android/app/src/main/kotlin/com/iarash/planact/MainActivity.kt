package com.iarash.planact

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/sms")
            .setMethodCallHandler { call, result -> SmsBridge.configureMethods(this, call, result) }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "planact/sms/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) { SmsBridge.attach(events) }
                override fun onCancel(arguments: Any?) { }
            })
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        SmsBridge.onRequestPermissionsResult(this, requestCode)
    }
}
