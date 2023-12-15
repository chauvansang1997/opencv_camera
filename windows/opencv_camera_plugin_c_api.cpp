#include "include/opencv_camera/opencv_camera_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "opencv_camera_plugin.h"

void OpencvCameraPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  opencv_camera::OpencvCameraPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
