package com.privileged.everyday_lilly

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    private val CHANNEL = "everyday_lilly/timelapse"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "generateTimelapse" -> {
                    android.util.Log.d("MainActivity", "MethodChannel called: starting timelapse generation")
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val args = call.arguments as Map<*, *>
                            val imagePaths = (args["imagePaths"] as List<*>).map { it.toString() }
                            val outputPath = args["outputPath"].toString()
                            val fps = (args["fps"] as Number).toDouble()
                            android.util.Log.d("MainActivity", "Calling encoder: ${imagePaths.size} images, fps=$fps")

                            val params = TimelapseEncoder.Params(
                                imagePaths = imagePaths,
                                outPath = outputPath,
                                fps = fps
                            )

                            val finalPath = TimelapseEncoder.encode(this@MainActivity, params)
                            runOnUiThread {
                                result.success(finalPath)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("ENCODER_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}