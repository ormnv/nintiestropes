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
        cv::Mat smileyP;
        cv::Mat smileyLL;
        cv::Mat smileyLR;
        cv::Mat smileyPU;
        cv::CascadeClassifier face_cascade;
//        cv::CascadeClassifier eyes_cascade;
//        cv::CascadeClassifier mouth_cascade;
    };
    
    FaceAnimator(Parameters parameters);
    virtual ~FaceAnimator() {};
    
    void detectAndAnimateFaces(cv::Mat& frame, cv::Mat& dest, int orientation);
    int getFaceCount();
    float getAvgFaceSize();
    float getAvgCenterness();
    std::vector<cv::Rect> getFaceRects();
    float getCenterness(cv::Rect face, float width, float height);
    void rotate(cv::Mat& src, double angle, cv::Mat& dst);
    
private:
    Parameters parameters_;
    cv::Mat mask_orig_;
    cv::Mat mask_must_;
    cv::Mat mask_smileyP_;
    cv::Mat mask_smileyLL_;
    cv::Mat mask_smileyLR_;
    cv::Mat mask_smileyPU_;
    cv::Mat frame_gray;
    cv::Mat dest_gray;
    int faceCount_;
    float avgFaceSize_;
    float avgCenterness_;
    std::vector<cv::Rect> newFaces;
    
    void putImage(cv::Mat& frame, const cv::Mat& image, const cv::Mat& alpha,
                  cv::Rect face, float shift);
    void PreprocessToGray(cv::Mat& frame);
    
    //Members for optimization
    void PreprocessToGray_optimized(cv::Mat& frame);
    cv::Mat accBuffer1;
    cv::Mat accBuffer2;
};

