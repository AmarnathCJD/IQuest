package com.example.iquest

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Suppress spammy Qualcomm gralloc metadata warnings
        try {
            Runtime.getRuntime().exec(arrayOf(
                "adb", "shell", "setprop", "log.tag.qdgralloc", "SUPPRESS"
            ))
            Runtime.getRuntime().exec(arrayOf(
                "adb", "shell", "setprop", "log.tag.PipelineWatcher", "SUPPRESS"
            ))
        } catch (_: Exception) {}
    }
}
