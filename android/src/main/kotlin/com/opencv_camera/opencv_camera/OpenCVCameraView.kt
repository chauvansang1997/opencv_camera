package com.opencv_camera.opencv_camera


import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.view.LayoutInflater
import android.view.View
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import org.opencv.android.CameraBridgeViewBase

import org.opencv.core.Mat

class OpenCVCameraView(
    private val context: Context,
    messenger: BinaryMessenger,
    private val id: Int
) : PlatformView, MethodChannel.MethodCallHandler, CameraBridgeViewBase.CvCameraViewListener2,
    PluginRegistry.RequestPermissionsResultListener {

    private var opencvCameraView: ExtendJavaCamera2View? = null
    private var currentRelativeLayout: View? = null
    private val cameraRequestCode = Shared.CAMERA_REQUEST_ID + this.id
    private var isRequestingPermission = false
    private var isPermissionGranted = false
    private var exponentFilter = 10
    private var cameraIndex = CameraBridgeViewBase.CAMERA_ID_FRONT
    private var permissionResult: MethodChannel.Result? = null

    private val channel: MethodChannel = MethodChannel(
        messenger, "opencv_camera$id"
    )

    init {
        Shared.binding?.addRequestPermissionsResultListener(this)

        channel.setMethodCallHandler(this)
        checkAndRequestPermission()
    }


    @SuppressLint("InflateParams")
    override fun getView(): View {
        val currentView = currentRelativeLayout

        return if (currentView == null) {

            val nativeView: View =
                LayoutInflater.from(context).inflate(R.layout.camera, null)

            val openGlView =
                nativeView.findViewById<ExtendJavaCamera2View>(R.id.opencv_gl_surface_view)


            openGlView.setCameraIndex(CameraBridgeViewBase.CAMERA_ID_FRONT)


            openGlView.setCvCameraViewListener(this)
            openGlView.enableView()
            if (hasCameraPermission) {
                openGlView.setCameraPermissionGranted()
            }

            opencvCameraView?.setCameraIndex(getCameraFacing())
            currentRelativeLayout = nativeView
            opencvCameraView = openGlView

            return nativeView

        } else {
            currentView
        }
    }

    override fun dispose() {
        opencvCameraView?.disableView()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Shared.setExponent -> {
                val arguments = call.arguments as? Map<*, *>
                if (arguments != null) {
                    val filter = arguments["exponent"] as Int? ?: 10
                    exponentFilter = filter
                }

                result.success(null)
            }

            "toggleCamera" -> switchCamera(result)
            "requestCameraPermission" -> requestCameraPermission(result)
            "setDimensions" -> {
                val arguments = call.arguments as? Map<*, *>
//                val width = arguments?.get("width") as? Double ?: 0.0
//                val height = arguments?.get("height") as? Double ?: 0.0
                val cameraFacing = arguments?.get("cameraFacing") as? Int?
                // Handle the "setDimensions" call with the received data

                if (cameraFacing != null) {
                    cameraIndex = cameraFacing
                    opencvCameraView?.setCameraIndex(getCameraFacing())
                }

                result.success(null)
            }
        }
    }

    override fun onCameraViewStarted(width: Int, height: Int) {

    }

    override fun onCameraViewStopped() {

    }

    private fun getCameraFacing(): Int {
        when (cameraIndex) {
            0 -> {
                return CameraBridgeViewBase.CAMERA_ID_BACK
            }

            1 -> {
                return CameraBridgeViewBase.CAMERA_ID_FRONT
            }
        }
        cameraIndex = 1
        return CameraBridgeViewBase.CAMERA_ID_FRONT
    }

    private fun switchCamera(result: MethodChannel.Result) {
        opencvCameraView?.disableView()
        cameraIndex = if (cameraIndex == 0) {
            1
        } else {
            0
        }
        val currentCameraIndex = getCameraFacing()
        val newCameraIndex =
            if (currentCameraIndex == CameraBridgeViewBase.CAMERA_ID_FRONT) CameraBridgeViewBase.CAMERA_ID_BACK
            else CameraBridgeViewBase.CAMERA_ID_FRONT
        opencvCameraView?.setCameraIndex(newCameraIndex)
        opencvCameraView?.enableView()
        result.success(newCameraIndex == CameraBridgeViewBase.CAMERA_ID_BACK)
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            // Camera permission is already granted
            result.success(true)
            opencvCameraView?.setCameraPermissionGranted()
            return
        }

        if (!isRequestingPermission) {
            isRequestingPermission = true
            isPermissionGranted = false
            permissionResult = result
            // Request camera permission
            Shared.activity?.requestPermissions(
                arrayOf(Manifest.permission.CAMERA),
                cameraRequestCode
            )
        }

        // The result will be handled in onRequestPermissionsResult
    }

    override fun onCameraFrame(inputFrame: CameraBridgeViewBase.CvCameraViewFrame): Mat {

        // get current camera frame as OpenCV Mat object
        val mat = inputFrame.rgba()

        // native call to process current camera frame
        processJavaFrame(
            mat.nativeObjAddr,
            DuoToneParam(exponent = exponentFilter, s1 = 0, s2 = 0, s3 = 3)
        )

        // return processed frame for live preview
        return mat
    }

    private val hasCameraPermission: Boolean
        get() = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != cameraRequestCode) return false
        isRequestingPermission = false

        val permissionGranted =
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        isPermissionGranted = permissionGranted

        if (isPermissionGranted) {
            opencvCameraView?.setCameraPermissionGranted()
        }


        permissionResult?.let {
            Shared.activity?.runOnUiThread {
                it.success(permissionGranted)
                permissionResult = null
            }
        }


        channel.invokeMethod(Shared.onPermissionSet, permissionGranted)

        return permissionGranted
    }


    private fun checkAndRequestPermission() {
        if (hasCameraPermission) {
            channel.invokeMethod(Shared.onPermissionSet, true)
            opencvCameraView?.setCameraPermissionGranted()
            return
        }

        if (!isRequestingPermission) {
            Shared.activity?.requestPermissions(
                arrayOf(Manifest.permission.CAMERA),
                cameraRequestCode
            )
        }
    }

    companion object {
        private external fun processJavaFrame(matAddress: Long, param: DuoToneParam)
    }

}