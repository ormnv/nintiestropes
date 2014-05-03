//
//  FaceAnimator.h
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
//#include "Processing.hpp"


class FaceAnimator
{
public:
    struct Parameters
    {
        cv::Mat glasses;
        cv::Mat mustache;
        cv::Mat smiley1;
        cv::Mat grinning;
        cv::CascadeClassifier face_cascade;
        cv::CascadeClassifier eyes_cascade;
        cv::CascadeClassifier mouth_cascade;
    };
    
    FaceAnimator(Parameters parameters);
    virtual ~FaceAnimator() {};
    
    void detectAndAnimateFaces(cv::Mat& frame);
    int getFaceCount();
    float getAvgFaceSize();
    
private:
    Parameters parameters_;
    cv::Mat mask_orig_;
    cv::Mat mask_must_;
    cv::Mat mask_smiley1_;
    cv::Mat mask_grinning_;
    cv::Mat frame_gray;
    int faceCount_;
    float avgFaceSize_;
    
    void putImage(cv::Mat& frame, const cv::Mat& image, const cv::Mat& alpha,
                  cv::Rect face, float shift);
    void PreprocessToGray(cv::Mat& frame);
    
    //Members for optimization
    void PreprocessToGray_optimized(cv::Mat& frame);
    cv::Mat accBuffer1;
    cv::Mat accBuffer2;
};

