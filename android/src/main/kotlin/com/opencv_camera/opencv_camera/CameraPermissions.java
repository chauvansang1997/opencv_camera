package com.opencv_camera.opencv_camera;



import android.Manifest;
import android.Manifest.permission;
import android.app.Activity;
import android.content.pm.PackageManager;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class CameraPermissions {
    private static final int CAMERA_REQUEST_ID = 9796;
    private boolean ongoing = false;

    public void requestPermissions(
            Activity activity, ResultCallback callback) {
//        if (ongoing) {
//            callback.onResult("cameraPermission", "Camera permission request ongoing");
//        }
//        final ResultCallback innerCallback = callback;
//        if (!hasCameraPermission(activity) || (!hasAudioPermission(activity))) {
//            activity.requestPermissions(
//
//            );
//            activity.addRequestPermissionsResultListener(
//                    new CameraRequestPermissionsListener(
//                            new ResultCallback() {
//                                @Override
//                                public void onResult(String errorCode, String errorDescription) {
//                                    ongoing = false;
//                                    innerCallback.onResult(errorCode, errorDescription);
//                                }
//                            }));
//            ongoing = true;
//            ActivityCompat.requestPermissions(
//                    activity, new String[]{Manifest.permission.CAMERA},
//                    CAMERA_REQUEST_ID);
//        } else {
//            // Permissions already exist. Call the callback with success.
//            callback.onResult(null, null);
//        }
    }

    private boolean hasCameraPermission(Activity activity) {
        return ContextCompat.checkSelfPermission(activity, permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;
    }

    private boolean hasAudioPermission(Activity activity) {
        return ContextCompat.checkSelfPermission(activity, permission.RECORD_AUDIO)
                == PackageManager.PERMISSION_GRANTED;
    }

    private static class CameraRequestPermissionsListener
            implements PluginRegistry.RequestPermissionsResultListener {
        final ResultCallback callback;

        private CameraRequestPermissionsListener(ResultCallback callback) {
            this.callback = callback;
        }

        @Override
        public boolean onRequestPermissionsResult(int id, String[] permissions, int[] grantResults) {
            if (id == CAMERA_REQUEST_ID) {
                if (grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                    callback.onResult("cameraPermission", "MediaRecorderCamera permission not granted");
                } else if (grantResults.length > 1
                        && grantResults[1] != PackageManager.PERMISSION_GRANTED) {
                    callback.onResult("cameraPermission", "MediaRecorderAudio permission not granted");
                } else {
                    callback.onResult(null, null);
                }
                return true;
            }
            return false;
        }
    }

    interface ResultCallback {
        void onResult(String errorCode, String errorDescription);
    }
}
