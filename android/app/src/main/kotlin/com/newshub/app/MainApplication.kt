package com.newshub.app

import android.app.Application
import io.flutter.embedding.android.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterSettings
import io.flutter.plugin.common.EventChannel

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FlutterEngineCache.getInstance().addForEngine(
            FlutterSettings().also { FlutterEngineCache.getInstance().addForEngine(it) }
        )
    }
}
