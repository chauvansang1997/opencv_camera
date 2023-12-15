// OpenCVCameraView.m
#import "OpenCVCameraView.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "VeinFilterWrapper.hpp"

#import <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

@interface OpenCVCameraView ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) CALayer *previewLayer;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) FlutterMethodChannel* channel;
@property (nonatomic, assign) int64_t viewId;
@property (nonatomic, assign) double width;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) int exponentFilter;
@property (nonatomic, assign) cv::Mat cvImage;  // OpenCV Mat to store the captured frame
@property (nonatomic, strong) VeinFilterWrapper *veinFilterWrapper;
@property (nonatomic, assign) AVCaptureDevicePosition currentCameraPosition; // Track the currently active camera
@property (nonatomic, assign) BOOL isCapturingPhoto; // Add this property
@property (nonatomic, copy) FlutterResult photoCaptureResult; // Add this property

@end

@implementation OpenCVCameraView

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    
    if (self = [super init]) {
        _veinFilterWrapper = [[VeinFilterWrapper alloc] init];
        _isCapturingPhoto = NO; // Initialize it to NO
        _videoDataOutputQueue = dispatch_queue_create("opencv_camera",DISPATCH_QUEUE_SERIAL);
        _viewId = viewId;
        _exponentFilter  = 20;
        NSString* channelName = [NSString stringWithFormat:@"opencv_camera%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        
        

        __weak __typeof__(self) weakSelf = self;
        
        [weakSelf requestCameraPermission:nil];
        
        [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
        }];
                
        _previewView = [[UIView alloc] initWithFrame:frame];
       
    }
    
    return self;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;

    if ([[call method] isEqualToString:@"setDimensions"]) {
        NSDictionary *arguments = (NSDictionary *)call.arguments;
        [weakSelf setDimensionsWithResult:result
                                          width:[arguments[@"width"] doubleValue] ?: 0
                                          height:[arguments[@"height"] doubleValue] ?: 0
                                          cameraFacing:[arguments[@"cameraFacing"] intValue] ?: 0];
        result(nil);  // Return NO to Flutter
    } else if ([[call method] isEqualToString:@"setExponent"]) {
        NSDictionary *arguments = (NSDictionary *)call.arguments;
        int filter = [arguments[@"exponent"] intValue] ?: 0;
        
        _exponentFilter = filter;
        result(nil);  // Return NO to Flutter
    } else if ([[call method] isEqualToString:@"requestCameraPermission"]) {
        // Call the requestCameraPermission method and pass the result
        [weakSelf requestCameraPermission:result];
    } else if ([[call method] isEqualToString:@"toggleCamera"]) {
        [weakSelf toggleCamera:result];
    } else if ([[call method] isEqualToString:@"captureCameraImage"]) {
//       [weakSelf captureCameraImage:result];
   }
   

}

- (void)sendPermissionEvent:(BOOL)granted {
    if (self.channel) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onPermissionSet" arguments:@{@"granted": @(granted)}];
        });
        
    }
}

- (void)setDimensionsWithResult:(FlutterResult)result
                          width:(double)width
                         height:(double)height
                         cameraFacing:(int)cameraFacing{
    
    self.previewView.frame = CGRectMake(0, 0, width, height);
    _width = width;
    _height = height;
    _imageView = [[UIImageView alloc] initWithFrame:_previewView.bounds];
    [self.previewView addSubview:_imageView];
    

    AVCaptureDevicePosition facing =[self captureDevicePositionFromInt:cameraFacing];
    
    [self setupCamera:facing];
    result(nil);
}

- (AVCaptureDevicePosition)captureDevicePositionFromInt:(NSInteger)intValue {
    switch (intValue) {
        case 0:
            return AVCaptureDevicePositionBack;
        case 1:
            return AVCaptureDevicePositionFront;
        default:
            return AVCaptureDevicePositionUnspecified; // You can choose another fallback value if needed
    }
}

- (UIView*)view {
    return _previewView;
}

// Request camera permission
- (void)requestCameraPermission:(FlutterResult)result {
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (![cameraDevice hasMediaType:AVMediaTypeVideo]) {

        [self sendPermissionEvent:NO]; // Permission denied

        if (result == nil) {
            NSLog(@"Result is nil");
            return;
        }
        
        // Camera is not available
        NSError *error = [NSError errorWithDomain:@"CameraNotAvailableDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Camera is not available."}];
        result([FlutterError errorWithCode:@"CAMERA_NOT_AVAILABLE" message:error.localizedDescription details:nil]);
        
        return;
    }
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status == AVAuthorizationStatusAuthorized) {
        // Permission granted, you can now use the camera
        NSLog(@"Camera permission is already granted");


        [self sendPermissionEvent:YES]; // Permission granted
        
        if (result == nil) {
            NSLog(@"Result is nil");
            return;
        }
        
        result(@YES);
        return;
    }
    
    if (status == AVAuthorizationStatusNotDetermined) {
          [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
              if (granted) {
                  // Permission granted, you can now use the camera
                  NSLog(@"Camera permission granted");
                  [self sendPermissionEvent:YES]; // Permission granted
                  
                  if (result == nil) {
                      NSLog(@"Result is nil");
                      return;
                  }
                  
                  result(@YES);  // Return YES to Flutter
              } else {
                  // Permission denied or restricted
                  NSLog(@"Camera permission denied or restricted");
                  [self sendPermissionEvent:NO]; // Permission denied
                  
                  if (result == nil) {
                      NSLog(@"Result is nil");
                      return;
                  }
                
                  result(@NO);  // Return NO to Flutter
              }
          }];
          return;
    }
    
    [self sendPermissionEvent:NO]; // Permission denied
    
    if (result == nil) {
        NSLog(@"Result is nil");
        return;
    }
    
    result(@NO);  // Return NO to Flutter
}


- (void)setupCamera:(AVCaptureDevicePosition) cameraPosition {
    _captureSession = [[AVCaptureSession alloc] init];
    _currentCameraPosition = cameraPosition;
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }

    // Get the new camera device based on the currentCameraPosition
     AVCaptureDevice *cameraDevice = nil;
     if (_currentCameraPosition == AVCaptureDevicePositionBack) {
         cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
     } else {
         // Use the front camera
         NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
         for (AVCaptureDevice *device in devices) {
             if (device.position == AVCaptureDevicePositionFront) {
                 cameraDevice = device;
                 break;
             }
         }
     }

    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&error];

    if (error == nil && [_captureSession canAddInput:input]) {
        [_captureSession addInput:input];

        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [_videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];


        if ([_captureSession canAddOutput:_videoDataOutput]) {
            [_captureSession addOutput:_videoDataOutput];
        }
        

        _previewLayer = [CALayer layer];

//        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
        _previewLayer.contentsGravity = kCAGravityResizeAspectFill;
//        _previewLayer.contentsGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.position = CGPointMake(_previewView.frame.size.width/2., _previewView.frame.size.height/2.);
        _previewLayer.affineTransform = CGAffineTransformMakeRotation( M_PI / 2 );
        _previewLayer.frame = _previewView.layer.bounds;
//        _previewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI / 2);

//        int rotation_angle = 0;
//
//              switch (defaultAVCaptureVideoOrientation) {
//                  case AVCaptureVideoOrientationLandscapeRight:
//                      rotation_angle = 270;
//                      break;
//                  case AVCaptureVideoOrientationPortraitUpsideDown:
//                      rotation_angle = 180;
//                      break;
//                  case AVCaptureVideoOrientationLandscapeLeft:
//                      rotation_angle = 90;
//                      break;
//                  case AVCaptureVideoOrientationPortrait:
//                  default:
//                      break;
//              }

        // Remove any existing sublayers
        for (CALayer *sublayer in _previewView.layer.sublayers) {
            [sublayer removeFromSuperlayer];
        }

        [_previewView.layer addSublayer:_previewLayer];
        
//        [_previewView.layer addSubview:_imageView];

//        self.parentView.layer.sublayers = nil;

//        [_previewView.layer insertSublayer:_previewLayer atIndex:0]; // Insert below all other views

        
        // Start the camera session on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self.captureSession startRunning];
        });
    } else {
        NSLog(@"Error setting up camera: %@", error.localizedDescription);
    }
}

- (void)toggleCamera:(FlutterResult)result {
    // Toggle the current camera position
    if (self.currentCameraPosition == AVCaptureDevicePositionBack) {
        self.currentCameraPosition = AVCaptureDevicePositionFront;
    } else {
        self.currentCameraPosition = AVCaptureDevicePositionBack;
    }
    
    // Switch the camera in the AVCaptureSession
    [self switchCamera];
    result(nil);
}

- (void)switchCamera {
    // Stop the current session
    [self.captureSession stopRunning];
    
    // Remove existing inputs
    for (AVCaptureInput *input in self.captureSession.inputs) {
        [self.captureSession removeInput:input];
    }
    
    // Get the new camera device based on the currentCameraPosition
    AVCaptureDevice *newCameraDevice = nil;
    if (self.currentCameraPosition == AVCaptureDevicePositionBack) {
        newCameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    } else {
        // Use the front camera
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionFront) {
                newCameraDevice = device;
                break;
            }
        }
    }
    
    if (newCameraDevice) {
        NSError *error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCameraDevice error:&error];
        
        if (error == nil && [self.captureSession canAddInput:newInput]) {
            [self.captureSession addInput:newInput];
            
            // Restart the session
            [self.captureSession startRunning];
        } else {
            NSLog(@"Error switching camera: %@", error.localizedDescription);
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // Handle the captured frame here and update the UIImageView
//    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
//    cv::Mat cvMat = [self cvMatFromUIImage:image];
//    cv::Mat filteredCvMat = [self applyFilterToMat:cvMat];
//    
//
//    UIImage *filteredImage = [self UIImageFromCVMat:filteredCvMat];
//    // Check the size
//    CGSize imageSize = filteredImage.size;
//    CGFloat width = imageSize.width;
//    CGFloat height = imageSize.height;
//    
//    // Get the size of self.imageView.image
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGSize targetSize = self.imageView.image.size;
//
//        // Resize the filteredImage to the target size
//        UIImage *resizedImage = [self resizeImage:filteredImage toSize:targetSize];
//
//        self.imageView.image = resizedImage;
//
//    });
    
    
    
      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      CVPixelBufferLockBaseAddress(imageBuffer, 0);
      
      uint8_t *base;
      int width, height, bytesPerRow;
      base = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
      width = (int)CVPixelBufferGetWidth(imageBuffer);
      height = (int)CVPixelBufferGetHeight(imageBuffer);
      bytesPerRow = (int)CVPixelBufferGetBytesPerRow(imageBuffer);
      
      Mat filteredCvMat = Mat(height, width, CV_8UC4, base);
      
      [self applyFilterToMat:filteredCvMat];
    
      CGImageRef imageRef = [self CGImageFromCVMat:filteredCvMat];
      UIImage *filteredImage = [self UIImageFromCVMat:filteredCvMat];

      dispatch_sync(dispatch_get_main_queue(), ^{
         self.previewLayer.contents = (__bridge id)imageRef;
      });
      
      CGImageRelease(imageRef);
      CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}


- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    CGImageRelease(quartzImage);

    return image;
}

- (void)applyFilterToMat:(Mat&)inputMat {
    // Apply your OpenCV filter logic here
    [_veinFilterWrapper applyFilterToMat:inputMat withS1:0 s2:0 s3:3 exponent:_exponentFilter];
}

- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );


    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

- (CGImageRef)CGImageFromCVMat:(Mat)cvMat {
    if (cvMat.elemSize() == 4) {
        cv::cvtColor(cvMat, cvMat, COLOR_BGRA2RGBA);
    }
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return imageRef;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);

    return cvMat;
}
- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);

    return cvMat;
}

@end
