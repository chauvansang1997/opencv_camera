package com.opencv_camera.opencv_camera

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class OpenCVCameraFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context?,
        viewId: Int,
        args: Any?
    ): PlatformView {

        return OpenCVCameraView(
            context = requireNotNull(context),
            id = viewId,
            messenger = messenger
        )
    }
}