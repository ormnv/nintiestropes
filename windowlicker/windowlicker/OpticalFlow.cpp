//
//  OpticalFlow.cpp
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#include "OpticalFlow.hpp"
#include "Processing.hpp"

#include <iostream> //FIXME

using namespace cv;
using namespace std;

inline float Min(float a, float b) { return a < b ? a : b; }
inline float Max(float a, float b) { return a > b ? a : b; }

OpticalFlow::OpticalFlow()
: m_fastDetector(cv::Ptr<cv::FeatureDetector>(new cv::FastFeatureDetector()), 500)
{
//    parameters_ = parameters;
    m_maxNumberOfPoints=50;
    avgSpeed=0;
    avgVelocity=0;
    pointNum=50;
    maxCorners=200;
    qualityLevel=0.01;
    minDistance=10;
    blockSize=3;
    useHarrisDetector=false;
    cv::Size subPixWinSize(10,10);
    cv::Size winSize(31,31);
    cv::TermCriteria termcrit(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS,20,0.03);
    maxLevel=3;
    flags=0;
    minEigThreshold=0.001;
    computeObject = false;
    detectObject = false;
    trackObject = false;
    
    //from tracking
     m_detector = cv::FeatureDetector::create("GridFAST");

}

// set maxCorners
void OpticalFlow::setMaxCorners(int max_c) {
    maxCorners = max_c;
}

// initialise tracker
void OpticalFlow::init(cv::Mat& image, // output image
                               cv::Mat& image1, // input image
                               std::vector<cv::Point2f>& points1) // output points array
{
    // initialise tracker
    cv::goodFeaturesToTrack(image1,
                            points1,
                            maxCorners,
                            qualityLevel,
                            minDistance,
                            cv::Mat(),
                            blockSize,
                            useHarrisDetector,
                            k);
    
    // refine corner locations
    cv::cornerSubPix(image1, points1, subPixWinSize, cv::Size(-1,-1), termcrit);
    
    size_t i;
    for( i = 0; i < points1.size(); i++ )
    {
        // draw points
        cv::circle( image, points1[i], 3, cv::Scalar(0,255,0), -1, 8);
    }
}

//! Processes a frame and returns output image
bool OpticalFlow::trackFlow(const cv::Mat& inputFrame, cv::Mat& outputFrame)
{
    inputFrame.copyTo(outputFrame);
    
    cv::cvtColor(inputFrame, m_nextImg, CV_BGRA2GRAY);

        
        if (m_mask.rows != inputFrame.rows || m_mask.cols != inputFrame.cols)
            m_mask.create(inputFrame.rows, inputFrame.cols, CV_8UC1);
        
        if (m_prevPts.size() > 0)
        {
            cv::calcOpticalFlowPyrLK(m_prevImg, m_nextImg, m_prevPts, m_nextPts, m_status, m_error);
        }
        
        m_mask = cv::Scalar(255);
        
        std::vector<cv::Point2f> trackedPts;
        
        for (size_t i=0; i<m_status.size(); i++)
        {
            if (m_status[i])
            {
                trackedPts.push_back(m_nextPts[i]);
                
                cv::circle (m_mask, m_prevPts[i], 15, cv::Scalar(0), CV_FILLED);
                cv::line (outputFrame, m_prevPts[i], m_nextPts[i], CV_RGB(0,250,0));
                cv::circle (outputFrame, m_nextPts[i], 3, CV_RGB(0,250,0), CV_FILLED);
            }
        }
        
        bool needDetectAdditionalPoints = trackedPts.size() < m_maxNumberOfPoints;
        if (needDetectAdditionalPoints)
        {
            m_detector->detect(m_nextImg, m_nextKeypoints, m_mask);
            int pointsToDetect = m_maxNumberOfPoints -  trackedPts.size();
            
            if (m_nextKeypoints.size() > pointsToDetect)
            {
                std::random_shuffle(m_nextKeypoints.begin(), m_nextKeypoints.end());
                m_nextKeypoints.resize(pointsToDetect);
            }
            
            std::cout << "Detected additional " << m_nextKeypoints.size() << " points" << std::endl;
            
            for (size_t i=0; i<m_nextKeypoints.size(); i++)
            {
                trackedPts.push_back(m_nextKeypoints[i].pt);
                cv::circle(outputFrame, m_nextKeypoints[i].pt, 5, cv::Scalar(255,0,255), -1);
            }
        }
        
        m_prevPts = trackedPts;
        m_nextImg.copyTo(m_prevImg);
    
    
    return true;
}

// track object
void OpticalFlow::trackObj(cv::Mat& image, // output image
                                cv::Mat& image1, // previous frame
                                cv::Mat& image2, // next frame
                                std::vector<cv::Point2f>& points1, // previous points
                                std::vector<cv::Point2f>& points2, // next points
                                cv::vector<uchar>& status, // status array
                                cv::vector<float>& err) // error array
{
    // tracking code
    cv::calcOpticalFlowPyrLK(image1,
                             image2,
                             points1,
                             points2,
                             status,
                             err,
                             winSize,
                             maxLevel,
                             termcrit,
                             flags,
                             minEigThreshold);
    
    // work out maximum X,Y keypoint values in the next_points keypoint vector
    cv::Point2f min(FLT_MAX, FLT_MAX);
    cv::Point2f max(FLT_MIN, FLT_MIN);
    
    // refactor the points array to remove points lost due to tracking error
    size_t i, k;
    for( i = k = 0; i < points2.size(); i++ )
    {
        if( !status[i] )
            continue;
        
        points2[k++] = points2[i];
        
        // find keypoints at the extremes
        min.x = Min(min.x, points2[i].x);
        min.y = Min(min.y, points2[i].y);
        max.x = Max(max.x, points2[i].x);
        max.y = Max(max.y, points2[i].y);
        
        // draw points
        cv::circle( image, points2[i], 3, cv::Scalar(0,255,0), -1, 8);
    }
    points2.resize(k);
    
    // Draw lines between the extreme points (square)
    cv::Point2f point0(min.x, min.y);
    cv::Point2f point1(max.x, min.y);
    cv::Point2f point2(max.x, max.y);
    cv::Point2f point3(min.x, max.y);
    cv::line( image, point0, point1, cv::Scalar( 0, 255, 0 ), 4 );
    cv::line( image, point1, point2, cv::Scalar( 0, 255, 0 ), 4 );
    cv::line( image, point2, point3, cv::Scalar( 0, 255, 0 ), 4 );
    cv::line( image, point3, point0, cv::Scalar( 0, 255, 0 ), 4 );
}

//! Returns true if this sample requires setting a reference image for latter use
bool OpticalFlow::isReferenceFrameRequired() const
{
    return true;
}

//! Sets the reference frame for latter processing
void OpticalFlow::setReferenceFrame(const cv::Mat& reference)
{
    cv::cvtColor(reference, imagePrev, CV_BGRA2GRAY);
    computeObject = true;
}

// Reset object keypoints and descriptors
void OpticalFlow::resetReferenceFrame()
{
    trackObject = false;
    computeObject = false;
}

//! Processes a frame and returns output image
bool OpticalFlow::processFrame(const cv::Mat& inputFrame, cv::Mat& outputFrame)
{
    // display the frame
    inputFrame.copyTo(outputFrame);
    
    // convert input frame to gray scale
    cv::cvtColor(inputFrame, outputFrame, CV_BGRA2GRAY);

    
    // prepare the tracking class
  //  OpticalFlow ot;
    //setMaxCorners(maxCorners);
    
    // begin tracking object
    if ( trackObject ) {
        trackObj(outputFrame,
                 imagePrev,
                 imageNext,
                 pointsPrev,
                 pointsNext,
                 status,
                 err);
        
        // check if the next points array isn't empty
        if ( pointsNext.empty() )
            trackObject = false;
    }
    
    // store the reference frame as the object to track
    if ( computeObject ) {
        init(outputFrame, imagePrev, pointsNext);
        trackObject = true;
        computeObject = false;
    }
    
    // backup previous frame
    imageNext.copyTo(imagePrev);
    
    // backup points array
    std::swap(pointsNext, pointsPrev);
    
    return true;
}
