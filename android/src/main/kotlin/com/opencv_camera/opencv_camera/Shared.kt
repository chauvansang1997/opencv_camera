package com.opencv_camera.opencv_camera

import android.annotation.SuppressLint
import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

@SuppressLint("StaticFieldLeak")
object Shared {
    const val CAMERA_REQUEST_ID = 513469796
    const val onPermissionSet = "onPermissionSet"
    const val setExponent = "setExponent"

    var activity: Activity? = null

    var binding: ActivityPluginBinding? = null
}