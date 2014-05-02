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
    ExtractAlpha(parameters_.glasses, mask_orig_);
    ExtractAlpha(parameters_.mustache, mask_must_);
}

void FaceAnimator::putImage(Mat& frame, const Mat& image, const Mat& alpha,
                            cv::Rect face, cv::Rect facialFeature, float shift)
{
    // Scale animation image
    float scale = 1.1;
    cv::Size featureSz;
    featureSz.width = scale * facialFeature.width;
    featureSz.height = scale * facialFeature.height;
    cv::Size newSz = cv::Size(featureSz.width,
                      float(image.rows) / image.cols * featureSz.width);
    Mat glasses;
    Mat mask;
    resize(image, glasses, newSz);
    resize(alpha, mask, newSz);
    
    // Find place for animation
    float coeff = (scale - 1.) / 2.;
    cv::Point origin(face.x + facialFeature.x - coeff * facialFeature.width,
                 face.y + facialFeature.y - coeff * facialFeature.height +
                 newSz.height * shift);
    cv::Rect roi(origin, newSz);
    cv::Mat roi4glass = frame(roi);
    
    alphaBlendC4(glasses, roi4glass, mask);
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
        
        //     std::vector<Rect> facialFeature;
        //       if (i % 2 == 0)
        //       {//detect eyes
        //            Mat eyesArea = faceROI(
        //                Rect(0, 0, faces[i].width, faces[i].height/2));
        //
        //            TS(DetectEyes);
        //            parameters_.eyes_cascade.detectMultiScale( eyesArea,
        //                facialFeature, 1.1, 2, CV_HAAR_FIND_BIGGEST_OBJECT,
        //                Size(faces[i].width * 0.55, faces[i].height * 0.13) );
        //            TE(DetectEyes);
        //
        //            if (facialFeature.size())
        //            {
        //                TS(DrawGlasses);
        //                putImage(frame, parameters_.glasses, mask_orig_,
        //                         faces[i], facialFeature[0], -0.1f);
        //                TE(DrawGlasses);
        
        const cv::Rect& currentFace = faces[i];
        //calculate two corner points to draw a rectangle
        cv::Point upLeftPoint(currentFace.x, currentFace.y);
        cv::Point bottomRightPoint = upLeftPoint + cv::Point(currentFace.width, currentFace.height);
        //draw rectangle around the face
        cv::rectangle(frame, upLeftPoint, bottomRightPoint, cv::Scalar(255,0,255), 4, 8, 0);
        
        //            }
        //      }
        //        else
        // {//detect mouth
        //            Point origin(0, faces[i].height/2);
        //            Mat mouthArea = faceROI(Rect(origin,
        //                Size(faces[i].width, faces[i].height/2)));
        //
        //            parameters_.mouth_cascade.detectMultiScale(
        //                mouthArea, facialFeature, 1.1, 2,
        //                CV_HAAR_FIND_BIGGEST_OBJECT,
        //                Size(faces[i].width * 0.2, faces[i].height * 0.13) );
        //
        //            if (facialFeature.size())
        //            {
        //                putImage(frame, parameters_.mustache, mask_must_,
        //                         faces[i], facialFeature[0] + origin, 0.3f);
        //            }
        //
        //            const cv::Rect& currentFace = faces[i];
        //            //calculate two corner points to draw a rectangle
        //            cv::Point upLeftPoint(currentFace.x, currentFace.y);
        //            cv::Point bottomRightPoint = upLeftPoint + cv::Point(currentFace.width, currentFace.height);
        //            //draw rectangle around the face
        //            cv::rectangle(frame, upLeftPoint, bottomRightPoint, cv::Scalar(0,255,255), 4, 8, 0);
        //    
        
        // }
    }
    
}