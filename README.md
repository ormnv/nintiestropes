OpenCV App

The app uses an existing tutorial of opencv examples from 2012 found here https://github.com/BloodAxe/OpenCV-Tutorial. My version of the app uses the UI as a base while making my own samples that mimic 90s music video effects. To make the tutorial work on arm64, I removed cvneon.h, cvneon.cpp and made the file extensions mm. For the time being, neon is not used to enhance perofrmance since the methods need to be replaced. It may be possible to implement the methods dependent on getGray to use neon for arm64 within the individual sample files themselves. OpenCv for iOS by Kornyakov and Shishkov contains an example where a filter is optimized by neon. Since this project will be using filters, the version provided there can be used. Comparing the original version of the app in the tutorial running with cvneon to my version running on arm64 without neon, there is no noticable difference in rendering the effects. The app is faster for some effects on arm64 even without cvneon. The Object Tracking sample does not with in the old version nor the new version. 

TODO:

-Update UI 

-Get Assets 

-Update methods converting to and from mat 

-Rewrite sample base to be simular to 

-CVNEON 
The cvneon class that was part of the original OpenCV iOS tutorial does not work with the arm64 architecture. The registers are different for arm64, so the old code won't work. For the time being, the cvneon methods were replaced by Specfically affecting: 

cvneon.cpp
	The error occurs in static void neon_asm_convert which is called by neon_cvtColorBGRA2GRAY.
	The error occurs in static void neon_asm_mat4_vec4_mul which is called by neon_transform_bgra. 

ImageFilterSample.cpp 
	ImageFiltersSample::sepia calls cv::neon_transform_bgra	
	ImageFiltersSample::contrastAndBrightnessAdjust calls cv::neon_transform_bgra	

SampleBase.cpp
	SampleBase::getGray which calls cv::neon_cvtColorBGRA2GRAY(input, gray)

CartoonFilter.cpp
ContourDetectionSample.cpp
EdgeDetectionSample.cpp
FeatureDetectionSample.cpp
ObjectTrackingSample.cpp
VideoTracking.cpp
	all call getGray

Resources:
	-OpenCv iOS Tutorial
	-Explanation of grey conversion with cvneon from 2012
	http://computer-vision-talks.com/articles/2012-11-06-maximizing-performance-grayscale-color-conversion-using-neon-and-cvparallel_for/
