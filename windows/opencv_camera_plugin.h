#ifndef FLUTTER_PLUGIN_OPENCV_CAMERA_PLUGIN_H_
#define FLUTTER_PLUGIN_OPENCV_CAMERA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace opencv_camera {

class OpencvCameraPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  OpencvCameraPlugin();

  virtual ~OpencvCameraPlugin();

  // Disallow copy and assign.
  OpencvCameraPlugin(const OpencvCameraPlugin&) = delete;
  OpencvCameraPlugin& operator=(const OpencvCameraPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace opencv_camera

#endif  // FLUTTER_PLUGIN_OPENCV_CAMERA_PLUGIN_H_
