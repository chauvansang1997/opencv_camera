// import 'package:flutter_test/flutter_test.dart';
// import 'package:opencv_camera/opencv_camera.dart';
// import 'package:opencv_camera/opencv_camera_platform_interface.dart';
// import 'package:opencv_camera/opencv_camera_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockOpencvCameraPlatform
//     with MockPlatformInterfaceMixin
//     implements OpencvCameraPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final OpencvCameraPlatform initialPlatform = OpencvCameraPlatform.instance;

//   test('$MethodChannelOpencvCamera is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelOpencvCamera>());
//   });

//   test('getPlatformVersion', () async {
//     OpencvCamera opencvCameraPlugin = OpencvCamera();
//     MockOpencvCameraPlatform fakePlatform = MockOpencvCameraPlatform();
//     OpencvCameraPlatform.instance = fakePlatform;

//     expect(await opencvCameraPlugin.getPlatformVersion(), '42');
//   });
// }
