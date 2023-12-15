//
//  LaneDetector.cpp
//  SimpleLaneDetection
//
//  Created by Anurag Ajwani on 28/04/2019.
//  Copyright © 2019 Anurag Ajwani. All rights reserved.
//

#include "VeinFilter.hpp"

using namespace cv;
using namespace std;

void VeinFilter::multi_clahe(cv::Mat &img, int num) {
    for (int i = 0; i < num; ++i) {
        cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(2.0, cv::Size(4 + i * 2, 4 + i * 2));
        clahe->apply(img, img);
    }
}

Mat VeinFilter::exponential_function(Mat channel, float exp) {
    Mat table(1, 256, CV_8U);

    for (int i = 0; i < 256; i++)
        table.at<uchar>(i) = min((int) pow(i, exp), 255);

    LUT(channel, table, channel);
    return channel;
}

void VeinFilter::apply_filter(Mat& filterMat, int s1, int s2, int s3, float exponent) {
    
    cvtColor(filterMat, filterMat, COLOR_BGR2GRAY);

    multi_clahe(filterMat, 4);

    float exp = 1.0f + (float)(exponent) / 100.0f;

    cvtColor(filterMat, filterMat, COLOR_GRAY2BGR);

    Mat channels[3];

    split(filterMat, channels);
   
    for (int i = 0; i < 3; i++) {
           if ((i == s1) || (i == s2)) {
               channels[i] = exponential_function(channels[i], exp);
           } else {
               if (s3) {
                   channels[i] = exponential_function(channels[i], 2 - exp);
               } else {
                   channels[i] = Mat::zeros(channels[i].size(), CV_8UC1);
               }
           }
    }

    vector<Mat> newChannels{channels[0], channels[1], channels[2]};

    merge(newChannels, filterMat);
}
