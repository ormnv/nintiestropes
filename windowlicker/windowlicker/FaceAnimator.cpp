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
//    ExtractAlpha(parameters_.glasses, mask_orig_);
//    ExtractAlpha(parameters_.mustache, mask_must_);
    ExtractAlpha(parameters_.smileyP, mask_smileyP_);
    ExtractAlpha(parameters_.smileyLL, mask_smileyLL_);
    ExtractAlpha(parameters_.smileyLR, mask_smileyLR_);
    ExtractAlpha(parameters_.smileyPU, mask_smileyPU_);
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

void FaceAnimator::rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    int len = std::max(src.cols, src.rows);
    Point2f pt(len/2., len/2.);
    Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);
    
    warpAffine(src, dst, r, cv::Size(src.cols, src.rows));

}

void FaceAnimator::detectAndAnimateFaces(cv::Mat& frame, cv::Mat& dest, int orientation)
{
    Mat emoji;
    Mat mask;
    Mat face;
    
    TS(Preprocessing);
    PreprocessToGray_optimized(frame);
    TE(Preprocessing);
    
    // Detect faces
    TS(DetectFaces);
    std::vector<cv::Rect> faces;
    parameters_.face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0, cv::Size(100, 100));
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
        switch (orientation) {
            case 0: //Portrait
            {
                int height = frame.size().height;
//                int width = frame.size().width;
//                cv::Point upLeftPoint1(height-currentFace.y, currentFace.x);
//                cv::Point bottomRightPoint00 = upLeftPoint1 + cv::Point(-currentFace.height, currentFace.width);
//                cv::rectangle (dest, upLeftPoint1, bottomRightPoint00, cv::Scalar(0,225,255), 4, 8, 0);
                cv::Rect newFace = cv::Rect(height-currentFace.y-currentFace.height, currentFace.x, currentFace.height, currentFace.width);

                //rotate(parameters_.smiley1, -90, emoji);
                //rotate(mask_smiley1_, -90, mask);
                putImage(dest, parameters_.smileyP, mask_smileyP_, newFace, 0.3f);
                break;
            }
            case 1: //LandscapeRight/ default
            {
//                cv::Point upLeftPoint1(currentFace.x, currentFace.y);
//                cv::Point bottomRightPoint1 = upLeftPoint1 + cv::Point(currentFace.width, currentFace.height);
//                cv::Point bottomRightPoint000 = upLeftPoint1 + cv::Point(10, 10);
//                cv::rectangle(dest, upLeftPoint1, bottomRightPoint000, cv::Scalar(0,0,255), 4, 8, 0);
//                cv::rectangle(dest, upLeftPoint1, bottomRightPoint1, cv::Scalar(55,0,255), 4, 8, 0);
                putImage(dest, parameters_.smileyLR, mask_smileyLR_, currentFace, 0.3f);
                break;
            }
            case 2: //LandscapeLeft
            {
                int height = frame.size().height;
                int width = frame.size().width;
                cv::Point upLeftPoint1(width-currentFace.x*.5, height-currentFace.y);
                cv::Point bottomRightPoint00 = upLeftPoint1 + cv::Point(-currentFace.width, -currentFace.height);
                cv::rectangle (dest, upLeftPoint1, bottomRightPoint00, cv::Scalar(0,225,255), 4, 8, 0);

                cv::Point upLeftPoint1_(currentFace.x, currentFace.y);
                cv::Point bottomRightPoint00_ = upLeftPoint1 + cv::Point(currentFace.width, currentFace.height);
                //cv::rectangle (dest, upLeftPoint1_, bottomRightPoint00_, cv::Scalar(0,225,255), 4, 8, 0);
                //cv::circle (dest, cv::Point(currentFace.x,currentFace.y), 1, cv::Scalar(0,225,255), 4, 8, 0);
                cv::circle (dest, cv::Point(width-currentFace.x+currentFace.width/2, height-currentFace.y-currentFace.height), 1, cv::Scalar(0,225,255), 4, 8, 0);

              //  cv::Rect newFace = cv::Rect(width-currentFace.x-currentFace.width, height-currentFace.y-currentFace.height, currentFace.width, currentFace.height);
                cv::Rect newFace = cv::Rect(width-currentFace.x/2-currentFace.width, height-currentFace.y-currentFace.height, currentFace.width, currentFace.height);

//                rotate(parameters_.smiley1, 180, emoji);
//                rotate(mask_smiley1_, 180, mask);
                //TODO: fix this hack
                if(width-currentFace.x/2<288 && height-currentFace.y<288)
                {
                   putImage(dest, parameters_.smileyLL, mask_smileyLL_, newFace, 0.3f);
                }
                break;
            }
            case 3: //Portrait Upsidedown
            {
                int height = frame.size().height;
                int width = frame.size().width;
                //                cv::Point upLeftPoint1(height-currentFace.y, currentFace.x);
                //                cv::Point bottomRightPoint00 = upLeftPoint1 + cv::Point(-currentFace.height, currentFace.width);
                //                cv::rectangle (dest, upLeftPoint1, bottomRightPoint00, cv::Scalar(0,225,255), 4, 8, 0);
                cv::Rect newFace = cv::Rect(currentFace.y, width-currentFace.x-currentFace.width, currentFace.height, currentFace.width);
                
                //rotate(parameters_.smiley1, 90, emoji);
                //rotate(mask_smiley1_, 90, mask)
                putImage(dest, parameters_.smileyPU, mask_smileyPU_, newFace, 0.3f);
                break;
            }
            default:
            {
                break;
            }
        }

    }
    
    faces.clear();

    
}