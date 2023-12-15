#import "OpencvCameraPlugin.h"
#import "OpenCVCameraViewFactory.h"

@implementation OpencvCameraPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    OpenCVCameraViewFactory* openCvViewFactory =
        [[OpenCVCameraViewFactory alloc] initWithMessenger:registrar.messenger];

  [registrar registerViewFactory:openCvViewFactory withId:@"native/open_cv_camera"];
    
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"opencv_camera"
            binaryMessenger:[registrar messenger]];
  OpencvCameraPlugin* instance = [[OpencvCameraPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
