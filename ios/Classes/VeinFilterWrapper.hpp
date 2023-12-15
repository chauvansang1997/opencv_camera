// VeinFilterWrapper.hpp

#import <opencv2/opencv.hpp>

@interface VeinFilterWrapper : NSObject

- (void)applyFilterToMat:(cv::Mat&)filterMat withS1:(int)s1 s2:(int)s2 s3:(int)s3 exponent:(float)exponent;

@end
