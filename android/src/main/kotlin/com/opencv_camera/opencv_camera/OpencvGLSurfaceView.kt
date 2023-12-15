package com.opencv_camera.opencv_camera

import android.app.Activity
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.widget.Toast
import org.opencv.android.CameraGLSurfaceView
import org.opencv.android.CameraGLSurfaceView.CameraTextureListener


class OpencvGLSurfaceView : CameraGLSurfaceView, CameraTextureListener {
    private var frontFacing = false

    constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs)
    constructor(context: Context?) : super(context, null)

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (e.action == MotionEvent.ACTION_DOWN) (context as Activity).openOptionsMenu()
        return true
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        super.surfaceCreated(holder)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        super.surfaceDestroyed(holder)
    }

    override fun onCameraViewStarted(width: Int, height: Int) {
        Shared.activity?.runOnUiThread {
            Toast.makeText(
                context,
                "onCameraViewStarted",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    override fun onCameraViewStopped() {
        Shared.activity?.runOnUiThread {
            Toast.makeText(
                context,
                "onCameraViewStopped",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    fun setFrontFacing(frontFacing: Boolean) {
        this.frontFacing = frontFacing
    }

    override fun onCameraTexture(texIn: Int, texOut: Int, width: Int, height: Int): Boolean {
        processFrame(texIn, texOut, width, height, frontFacing)
        return true
    }

    companion object {
        private external fun processFrame(
            tex1: Int,
            tex2: Int,
            w: Int,
            h: Int,
            frontFacing: Boolean
        )
    }
}