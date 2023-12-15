////
////  OpenCVCameraViewFactory.m
////  opencv_camera
////
////  Created by DevMobile on 11/12/2023.
////
//
//#import "OpenCVCameraViewFactory.h"
//
//@implementation OpenCVCameraViewFactory
//
//@end


// OpenCVCameraViewFactory.m
#import "OpenCVCameraViewFactory.h"
#import "OpenCVCameraView.h"
@implementation OpenCVCameraViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    OpenCVCameraView *opencvCameraView = [[OpenCVCameraView alloc] initWithFrame:frame
                                                                  viewIdentifier:viewId
                                                                  arguments:args
                                                                  binaryMessenger:_messenger];
    return opencvCameraView;
}

@end
