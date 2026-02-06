package com.dpresse.dpresse

import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dpresse/cookies")
            .setMethodCallHandler { call, result ->
                if (call.method == "getCookies") {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val cookies = CookieManager.getInstance().getCookie(url)
                        result.success(cookies)
                    } else {
                        result.error("INVALID_ARG", "URL is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
