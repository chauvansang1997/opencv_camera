//
//  OpenCVCameraView.h
//  Pods
//
//  Created by DevMobile on 10/12/2023.
//
#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <opencv2/opencv.hpp>
#endif


#ifndef OpenCVCameraView_h
#define OpenCVCameraView_h

@interface OpenCVCameraView : NSObject <FlutterPlatformView, AVCaptureVideoDataOutputSampleBufferDelegate>
- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

- (UIView*)view;


@end
#endif /* OpenCVCameraView_h */
