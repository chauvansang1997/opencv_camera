//
//  LaneDetector.hpp
//  SimpleLaneDetection
//
//  Created by Anurag Ajwani on 28/04/2019.
//  Copyright © 2019 Anurag Ajwani. All rights reserved.
//

#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

class VeinFilter {
    
    public:
    
    /*
     Returns image with lane overlay
     */
    void apply_filter(Mat& filterMat,int s1, int s2, int s3, float exponent);
    
    private:
    
    /*
     Filters yellow and white colors on image
     */
    void multi_clahe(Mat &img, int num);
    
    Mat exponential_function(Mat channel, float exp);
};
