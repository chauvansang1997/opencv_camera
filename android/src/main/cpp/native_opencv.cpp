#include <opencv2/opencv.hpp>
#include <chrono>
#include <opencv2/imgproc.hpp>
#include <opencv2/photo.hpp>
#include <opencv2/highgui.hpp>
#include "general_funtion.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <string>
#include <cstdint>
#include <cstring>

#include <jni.h>
#include <GLES2/gl2.h>

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32)
#define IS_WIN32
#endif

#ifdef __ANDROID__

#include <android/log.h>
#include <opencv2/imgproc/types_c.h>
#include <jni.h>

#endif

#ifdef IS_WIN32
#include <windows.h>
#endif

#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it visible
#define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
// Marking a function for export
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

using namespace cv;
using namespace std;

struct DuoToneParam {
    float exponent;
    int s1; // value from 0-2 (0 : BLUE n1 : GREEN n2 : RED)
    int s2; // value from 0-3 (0 : BLUE n1 : GREEN n2 : RED n3 : NONE)
    int s3; // (0 : DARK n1 : LIGHT)
};

long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch())
            .count();
}


extern "C"
JNIEXPORT void JNICALL
Java_com_opencv_1camera_opencv_1camera_OpencvGLSurfaceView_00024Companion_processFrame(JNIEnv *env,
                                                                                       jobject thiz,
                                                                                       jint texIn,
                                                                                       jint texOut,
                                                                                       jint w,
                                                                                       jint h,
                                                                                       jboolean front_facing) {
    static UMat m;

    m.create(h, w, CV_8UC4);


    // expecting FBO to be bound, read pixels to mat
    glReadPixels(0, 0, m.cols, m.rows, GL_RGBA, GL_UNSIGNED_BYTE, m.getMat(ACCESS_WRITE).data);


    // Check if we should flip image due to frontFacing
    // I don't think this should be required, but I can't find
    // a way to get the OpenCV Android SDK to do this properly
    // (also, time taken to flip image is negligible)
    if (front_facing) {
        flip(m, m, 1);
    }


    cvtColor(m, m, CV_BGRA2GRAY);
    Laplacian(m, m, CV_8U);
    multiply(m, 10, m);
    cvtColor(m, m, CV_GRAY2BGRA);

    // write back
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texOut);

    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, m.cols, m.rows, GL_RGBA, GL_UNSIGNED_BYTE,
                    m.getMat(ACCESS_READ).data);
}

void multi_clahe(cv::Mat &img, int num) {
    for (int i = 0; i < num; ++i) {
        cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(2.0, cv::Size(4 + i * 2, 4 + i * 2));
        clahe->apply(img, img);
    }
}


Mat exponential_function(Mat channel, float exp) {
    Mat table(1, 256, CV_8U);

    for (int i = 0; i < 256; i++)
        table.at<uchar>(i) = min((int) pow(i, exp), 255);

    LUT(channel, table, channel);
    return channel;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_opencv_1camera_opencv_1camera_OpenCVCameraView_00024Companion_processJavaFrame(JNIEnv *env,
                                                                                        jobject thiz,
                                                                                        jlong mat_address,
                                                                                        jobject param) {
    jclass duoToneParam = env->GetObjectClass(param);
    jfieldID s1Field = env->GetFieldID(duoToneParam, "s1", "I");
    jfieldID s2Field = env->GetFieldID(duoToneParam, "s2", "I");
    jfieldID s3Field = env->GetFieldID(duoToneParam, "s3", "I");
    jfieldID exponentField = env->GetFieldID(duoToneParam, "exponent", "I");
    jint exponent = env->GetIntField(param, exponentField);
    jint s1 = env->GetIntField(param, s1Field);
    jint s2 = env->GetIntField(param, s2Field);
    jint s3 = env->GetIntField(param, s3Field);

    env->DeleteLocalRef(duoToneParam);


    Mat &filterMat = *(Mat *) mat_address;

    cvtColor(filterMat, filterMat, CV_RGBA2GRAY);

    multi_clahe(filterMat, 4);

    float exp = 1.0f + (float)(exponent) / 100.0f;


    cvtColor(filterMat, filterMat, CV_GRAY2BGR);

    Mat channels[3];

    split(filterMat, channels);
//    channels[0] = cv::Mat::zeros(    channels[0].rows,     channels[0].cols, CV_8UC1);  // Zero out blue channel
//    channels[1] = cv::Mat::zeros(    channels[1].rows,     channels[1].cols, CV_8UC1);  // Zero out green channel
//    channels[2] = exponential_function(channels[2], 2 - exp);
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

//    platform_log("apply_mat_duo_tone_filter:  param: %d,s1: %d,s2: %d,s3: %d", exponent, s1,
//                 s2, s3);

//    Laplacian(filterMat, filterMat, CV_8U);
//    multiply(filterMat, 10, filterMat);
//    multiply(filterMat, 10, filterMat);
//    cvtColor(filterMat, filterMat, CV_GRAY2RGBA);

}