// OpenCVCameraViewFactory.h
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface OpenCVCameraViewFactory : NSObject <FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end
