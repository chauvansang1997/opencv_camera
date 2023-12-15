// VeinFilterWrapper.mm

#import "VeinFilterWrapper.hpp"
#include "cpp/VeinFilter.hpp"

@implementation VeinFilterWrapper {
    VeinFilter veinFilter;
}

- (void)applyFilterToMat:(cv::Mat&)filterMat withS1:(int)s1 s2:(int)s2 s3:(int)s3 exponent:(float)exponent {
    veinFilter.apply_filter(filterMat, s1, s2, s3, exponent);
}

@end
