import 'package:flutter/material.dart';
import 'package:opencv_camera_example/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:opencv_camera/opencv_camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _opencvKey =
      const GlobalObjectKey<State<StatefulWidget>>('opencv_view');
  bool _isPermissionAccept = false;

  @override
  void initState() {
    // Permission.camera.request();
    PermissionUtils.handleAccessPermission(
      permission: Permission.camera,
      context: context,
      onPermissionAccepted: () {
        setState(() {
          _isPermissionAccept = true;
        });
      },
      onPermissionPermanentlynDenied: () {
        setState(() {
          _isPermissionAccept = true;
        });
      },
    );
    super.initState();
  }

  double _currentSliderValue = 20;
  QpencvCameraController? _controller;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: _isPermissionAccept
            ? SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: OpencvCameraView(
                        key: _opencvKey,
                        cameraFacing: CameraFacing.front,
                        onQpencvCameraCreated: (controller) {
                          _controller = controller;

                          _controller?.updateDimensions();
                        },
                      ),
                    ),
                    Slider(
                      value: _currentSliderValue,
                      divisions: 100,
                      max: 100,
                      onChanged: (value) {
                        _controller?.setExponent(value.toInt());
                        setState(() {
                          _currentSliderValue = value;
                        });
                      },
                    )
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
