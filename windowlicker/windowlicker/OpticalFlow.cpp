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
    avgMagnitude=0;
    //    maxCorners=200;
    //    qualityLevel=0.01;
    //    minDistance=10;
    //    blockSize=3;
    //    useHarrisDetector=false;
    //    cv::Size subPixWinSize(10,10);
    //    cv::Size winSize(31,31);
    //    cv::TermCriteria termcrit(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS,20,0.03);
    //    maxLevel=3;
    //    flags=0;
    //    minEigThreshold=0.001;
    //    computeObject = false;
    //    detectObject = false;
    //    trackObject = false;
    
    //from tracking
    m_detector = cv::FeatureDetector::create("GridFAST");
    
}

// set maxCorners
void OpticalFlow::setMaxCorners(int max_c) {
    maxCorners = max_c;
}

// set maxCorners
float OpticalFlow::getAvgMagnitude() {
    return avgMagnitude;
}

// set maxCorners
float OpticalFlow::getAvgSlope() {
    return avgSlope;
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
    
    //reset avgMagnitude and avgSlope
    avgMagnitude = 0;
    avgSlope =0;
    
    if (m_mask.rows != inputFrame.rows || m_mask.cols != inputFrame.cols)
        m_mask.create(inputFrame.rows, inputFrame.cols, CV_8UC1);
    
    if (m_prevPts.size() > 0)
    {
        cv::calcOpticalFlowPyrLK(m_prevImg, m_nextImg, m_prevPts, m_nextPts, m_status, m_error);
        //int rigidTransform = cv::estimateRigidTransform(m_prevPts, m_nextPts, 1);
    }
    
    m_mask = cv::Scalar(255);
    
    std::vector<cv::Point2f> trackedPts;
    std::vector<float> diffX;
    std::vector<float> diffY;
    std::vector<float> magnitudes;
    std::vector<float> directions;
    float total;
    float num =trackedPts.size();
    float slope;
    
    
    for (size_t i=0; i<m_status.size(); i++)
    {
        if (m_status[i])
        {
            trackedPts.push_back(m_nextPts[i]);
            
            cv::circle (m_mask, m_prevPts[i], 15, cv::Scalar(0), CV_FILLED);
            cv::line (outputFrame, m_prevPts[i], m_nextPts[i], CV_RGB(0,250,0));
            cv::circle (outputFrame, m_nextPts[i], 3, CV_RGB(255,255,204), CV_FILLED);
            
            //get line length
            float diffX = m_nextPts[i].x-m_prevPts[i].x;
            float diffY = m_nextPts[i].y-m_prevPts[i].y;
            float diff2 = diffX*diffX+diffY*diffY;
            total+=sqrt(diff2);
            slope += diffY/diffX;
            
        }
    }
    
    avgMagnitude = total/num;
    avgSlope=slope/num;
    
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

