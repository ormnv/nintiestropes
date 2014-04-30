#include "Processing.hpp"

using namespace cv;

void alphaBlendC1(const Mat& src, Mat& dst, const Mat& alpha)
{
    for (int i = 0; i < src.rows; i++)
        for (int j = 0; j < src.cols; j++)
        {
            uchar alpha_value = alpha.at<uchar>(i, j);
            if (alpha_value != 0)
            {
                float text_weight = static_cast<float>(alpha_value) / 255.0f;
                dst.at<uchar>(i, j) = text_weight * src.at<uchar>(i, j) +
                (1 - text_weight) * dst.at<uchar>(i, j);
            }
        }
}

void alphaBlendC4(const Mat& src, Mat& dst, const Mat& alpha)
{
    for (int i = 0; i < src.rows; i++)
        for (int j = 0; j < src.cols; j++)
        {
            uchar alpha_value = alpha.at<uchar>(i, j);
            if (alpha_value != 0)
            {
                float weight = float(alpha_value) / 255.f;
                dst.at<Vec4b>(i, j) = weight * src.at<Vec4b>(i, j) +
                (1 - weight) * dst.at<Vec4b>(i, j);
            }
        }
}

//void ExtractAlpha(cv::Mat& rgbaSrc, cv::Mat& alpha)
//{
//    std::vector<Mat> channels;
//    split(rgbaSrc, channels);
//    channels[3].copyTo(alpha);
//}