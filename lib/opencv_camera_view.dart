import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_camera/types/camera_exception.dart';
import 'package:opencv_camera/types/camera_facing.dart';
import 'package:flutter/foundation.dart';

typedef PermissionSetCallback = void Function(
    QpencvCameraController controller, bool pessmissionAccept);
typedef QpencvCameraCreatedCallback = void Function(
    QpencvCameraController controller);

class OpencvCameraView extends StatefulWidget {
  const OpencvCameraView({
    required GlobalKey<State<StatefulWidget>> key,
    required this.cameraFacing,
    required this.onQpencvCameraCreated,
    this.onPermissionSet,
  }) : super(key: key);

  /// [onQpencvCameraCreated] gets called when the view is created
  final QpencvCameraCreatedCallback onQpencvCameraCreated;

  /// Calls the provided [onPermissionSet] callback when the permission is set.
  final PermissionSetCallback? onPermissionSet;

  /// Set which camera to use on startup.
  ///
  /// [cameraFacing] can either be CameraFacing.front or CameraFacing.back.
  /// Defaults to CameraFacing.back
  final CameraFacing cameraFacing;
  @override
  State<OpencvCameraView> createState() => OpencvCameraViewState();
}

class OpencvCameraViewState extends State<OpencvCameraView> {
  late MethodChannel _channel;

  @override
  void initState() {
    super.initState();
    // _observer = LifecycleEventHandler(resumeCallBack: updateDimensions);
    // WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  Widget build(BuildContext context) {
    return _getPlatformOpencvCameraView();
  }

  Widget _getPlatformOpencvCameraView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: 'native/open_cv_camera',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );

      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'native/open_cv_camera',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );

      default:
        return Text(
            "Trying to use the default opencvView implementation for $defaultTargetPlatform but there isn't a default one");
    }
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('opencv_camera$id');

    // Start scan after creation of the view
    final controller = QpencvCameraController._(
      channel: _channel,
      opencvKey: widget.key as GlobalKey<State<StatefulWidget>>,
      cameraFacing: widget.cameraFacing,
    );

    // Initialize the controller for controlling the OpencvCameraView
    widget.onQpencvCameraCreated(controller);
  }
}

class QpencvCameraController {
  QpencvCameraController._({
    required MethodChannel channel,
    required GlobalKey opencvKey,
    required CameraFacing cameraFacing,
    PermissionSetCallback? onPermissionSet,
  })  : _channel = channel,
        _cameraFacing = cameraFacing,
        _opencvKey = opencvKey {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPermissionSet':
          if (call.arguments != null && call.arguments is bool) {
            _hasPermissions = call.arguments;
            if (onPermissionSet != null) {
              onPermissionSet(this, _hasPermissions);
            }
          }
          break;
      }
    });
  }

  final MethodChannel _channel;
  final CameraFacing _cameraFacing;
  final GlobalKey _opencvKey;

  bool _hasPermissions = false;
  bool get hasPermissions => _hasPermissions;

  Future<bool> requestCameraPermission() async {
    final requestPermission =
        await _channel.invokeMethod('requestCameraPermission');

    if (requestPermission is bool) {
      return requestPermission;
    }

    return false;
  }

  void toggleCamera() {
    _channel.invokeMethod('toggleCamera');
  }

  void setExponent(int filter) {
    _channel.invokeMethod('setExponent', {'exponent': filter});
  }

  /// Updates the view dimensions for iOS.
  Future<bool> updateDimensions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Add small delay to ensure the render box is loaded
      await Future.delayed(const Duration(milliseconds: 300));
      if (_opencvKey.currentContext == null) return false;
      final renderBox =
          _opencvKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) {
        return false;
      }

      try {
        await _channel.invokeMethod('setDimensions', {
          'width': renderBox.size.width,
          'height': renderBox.size.height,
          'cameraFacing': _cameraFacing.index,
        });
        return true;
      } on PlatformException catch (e) {
        throw CameraException(e.code, e.message);
      }
    }
    return false;
  }
}
