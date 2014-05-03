//
//  FaceAnimator.cpp
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#include "FaceAnimator.hpp"
#include "Processing.hpp"
#include "opencv2/imgproc/imgproc.hpp"

#include <iostream> //FIXME

using namespace cv;
using namespace std;

FaceAnimator::FaceAnimator(Parameters parameters)
{
    parameters_ = parameters;
    faceCount_=0;
    avgFaceSize_=0;
    ExtractAlpha(parameters_.glasses, mask_orig_);
    ExtractAlpha(parameters_.mustache, mask_must_);
    ExtractAlpha(parameters_.smiley1, mask_smiley1_);
    ExtractAlpha(parameters_.grinning, mask_grinning_);
}


void FaceAnimator::putImage(Mat& frame, const Mat& image, const Mat& alpha,
                            cv::Rect face, float shift)
{
    // Scale animation image
    float scale = 1.1;
    cv::Size featureSz;
    featureSz.width = scale * face.width;
    featureSz.height = scale * face.height;
    //cv::Size newSz = cv::Size(featureSz.width, float(image.rows) / image.cols * featureSz.width);
//    cv::Size newSz = cv::Size(featureSz.width, featureSz.height);
        cv::Size newSz = cv::Size(face.width, face.height);

    Mat smiley1;
    Mat mask;
    resize(image, smiley1, newSz);
    resize(alpha, mask, newSz);
    
    // Find place for animation
    //float coeff = (scale - 1.) / 2.;
//    cv::Point origin(face.x +featureSz.width,
//                     face.y +
//                     newSz.height);
    cv::Point origin(face.x, face.y);
    cv::Point lowerRight(face.x+face.width, face.y+face.height);
    cv::Rect roi(origin, newSz);
    cv::Mat roi4emoji = frame(roi);
    
    alphaBlendC4(smiley1, roi4emoji, mask);
}

static inline bool FaceSizeComparer(const cv::Rect& r1, const cv::Rect& r2)
{
    return r1.area() > r2.area();
}

void FaceAnimator::PreprocessToGray(cv::Mat& frame)
{
    cvtColor( frame, frame_gray, CV_RGBA2GRAY );
    equalizeHist( frame_gray, frame_gray );
}

void FaceAnimator::PreprocessToGray_optimized(cv::Mat& frame)
{
    frame_gray.create(frame.size(), CV_8UC1);
    accBuffer1.create(frame.size(), frame.type());
    accBuffer2.create(frame.size(), CV_8UC1);
    
    cvtColor_Accelerate(frame.data, frame.step,
                        frame_gray.data, frame_gray.step,
                        accBuffer1.data, accBuffer1.step,
                        accBuffer2.data, accBuffer2.step,
                        frame.rows, frame.cols);
    
    equalizeHist_Accelerate(frame_gray.data, frame_gray.step,
                            frame_gray.data, frame_gray.step,
                            frame_gray.rows, frame_gray.cols);
}

int FaceAnimator::getFaceCount(){
    return faceCount_;
}

float FaceAnimator::getAvgFaceSize(){
    return avgFaceSize_;
}

void FaceAnimator::detectAndAnimateFaces(cv::Mat& frame)
{
    TS(Preprocessing);
    PreprocessToGray_optimized(frame);
    TE(Preprocessing);
    
    // Detect faces
    TS(DetectFaces);
    std::vector<cv::Rect> faces;
    parameters_.face_cascade.detectMultiScale(frame_gray, faces, 1.1,
                                              2, 0, cv::Size(100, 100));
    cout << "Found faces: " << faces.size() << endl;
    TE(DetectFaces);
    
    // Sort faces by size in descending order
    sort(faces.begin(), faces.end(), FaceSizeComparer);
    faceCount_=faces.size();
    
    for ( size_t i = 0; i < faces.size(); i++ )
    {
        Mat faceROI = frame_gray( faces[i] );
        
        const cv::Rect& currentFace = faces[i];
        //calculate two corner points to draw a rectangle
        cv::Point upLeftPoint(currentFace.x, currentFace.y);
        cv::Point bottomRightPoint = upLeftPoint + cv::Point(currentFace.width, currentFace.height);
        putImage(frame, parameters_.smiley1, mask_smiley1_, currentFace, 0.3f);

    }
    
}