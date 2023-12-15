package com.opencv_camera.opencv_camera
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry.SurfaceTextureEntry


/** OpencvCameraPlugin */
class OpencvCameraPlugin: FlutterPlugin, ActivityAware  {
  private var channel: MethodChannel? = null
  private lateinit var binding: FlutterPlugin.FlutterPluginBinding
  private val cameraPermissions = CameraPermissions()
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterPluginBinding.platformViewRegistry
      .registerViewFactory(
        VIEW_TYPE_ID,
        OpenCVCameraFactory(flutterPluginBinding.binaryMessenger)
      )
    binding = flutterPluginBinding
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // Leave empty
    // Nullifying QrShared.activity and QrShared.binding here will cause errors if plugin is detached by another plugin
  }

  override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
    Shared.activity = activityPluginBinding.activity
    Shared.binding = activityPluginBinding
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Shared.activity = null
    Shared.binding = null
  }

  override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
    Shared.activity = activityPluginBinding.activity
    Shared.binding = activityPluginBinding
  }

  override fun onDetachedFromActivity() {
    Shared.activity = null
    Shared.binding = null
  }

  companion object {
    init {
      // Load your native library here
      System.loadLibrary("native-lib")
    }
    private const val VIEW_TYPE_ID = "native/open_cv_camera"
  }


}
