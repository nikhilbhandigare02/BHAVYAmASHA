package io.lite.bhavya_maasha

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "medixcel/device_id"
    private val TAG = "DeviceID"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Setting up MethodChannel")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            
            if (call.method == "getAndroidId") {
                try {
                    val androidId = getAndroidId()
                    Log.d(TAG, "Android ID retrieved: $androidId")
                    result.success(androidId)
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting Android ID: ${e.message}")
                    result.error("ERROR", e.message, null)
                }
            } else {
                Log.d(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun getAndroidId(): String {
        return try {
            val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
            Log.d(TAG, "Raw Android ID from Settings: $androidId")
            
            if (androidId.isNullOrEmpty()) {
                "Unknown"
            } else {
                androidId
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception getting Android ID: ${e.message}")
            "Error: ${e.message}"
        }
    }
}
