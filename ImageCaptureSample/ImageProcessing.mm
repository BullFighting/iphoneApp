//
//  ViewController.m
//  20141214
//
//  Created by Yumiko Kokubu on 2014/12/14.
//  Copyright (c) 2014年 國分 友美子. All rights reserved.
//

#import "ImageProcessing.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>

using namespace cv;

@implementation ImageProcessing

+(int)imageJudgment:(UIImage *)image{

    int  centerX = [self redPosition:[self matWithImage:image]];
    int signalFlag = [self signalDecision:image centerX:centerX];
    return signalFlag;
    
}
+ (int)signalDecision:(UIImage *)image centerX:(int)centerX{

    float rateX = centerX/image.size.width;
    NSLog(@"centerX : %d",centerX);
    NSLog(@"width : %f",image.size.width);
    NSLog(@"rateX : %f",rateX);
    int signalFlag;

    if (rateX <= 0.0) {
        signalFlag  = 4;
    }else if(rateX < 2.0/5.0 ){
        signalFlag = 1;
        NSLog(@"左");
    }else if (rateX < 3.0/5.0){
        signalFlag = 2;
        NSLog(@"中央");
    }else if (rateX < 1.0){
        signalFlag = 3;
        NSLog(@"右");
    }else{
        signalFlag = 4;
        NSLog(@"停止");
    }
    return signalFlag;
}

+ (cv::Mat)matWithImage:(UIImage*)image
{
    // 画像の回転を補正する（内蔵カメラで撮影した画像などでおかしな方向にならないようにする）
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    
    
    NSLog(@"size(%f,%f)",image.size.width,image.size.height);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // UIImage -> cv::Mat
    cv::Mat mat;
    
    UIImageToMat(image, mat);
    return mat;
}

+(int)redPosition:(cv::Mat)src{
    cv::Mat dst;
    
    cv::Mat imgThresholded;
    
    int iLowH = 190;
    int iHighH = 255;
    
    int iLowS = 0;
    int iHighS = 255;
    
    int iLowV = 0;
    int iHighV = 155;
    
    colorExtraction(&src, &dst, CV_8S, iLowH, iHighH, iLowS, iHighS, iLowV, iHighV);
    
    return redMoment(&dst, &imgThresholded, iLowH, iHighH, iLowS, iHighS, iLowV, iHighV);
    
}

void colorExtraction(cv::Mat* src, cv::Mat* dst,
                     int code,
                     int ch1Lower, int ch1Upper,
                     int ch2Lower, int ch2Upper,
                     int ch3Lower, int ch3Upper
                     )
{
    cv::Mat colorImage;
    int lower[3];
    int upper[3];
    
    cv::Mat lut = cv::Mat(256, 1, CV_8UC3);
    
    cv::cvtColor(*src, colorImage, code);
    
    lower[0] = ch1Lower;
    lower[1] = ch2Lower;
    lower[2] = ch3Lower;
    
    upper[0] = ch1Upper;
    upper[1] = ch2Upper;
    upper[2] = ch3Upper;
    
    for (int i = 0; i < 256; i++){
        for (int k = 0; k < 3; k++){
            if (lower[k] <= upper[k]){
                if ((lower[k] <= i) && (i <= upper[k])){
                    lut.data[i*lut.step+k] = 255;
                }else{
                    lut.data[i*lut.step+k] = 0;
                }
            }else{
                if ((i <= upper[k]) || (lower[k] <= i)){
                    lut.data[i*lut.step+k] = 255;
                }else{
                    lut.data[i*lut.step+k] = 0;
                }
            }
        }
    }
    
    //LUTを使用して二値化
    cv::LUT(colorImage, lut, colorImage);
    
    //Channel毎に分解
    std::vector<cv::Mat> planes;
    cv::split(colorImage, planes);
    
    //マスクを作成
    cv::Mat maskImage;
    cv::bitwise_and(planes[0], planes[1], maskImage);
    cv::bitwise_and(maskImage, planes[2], maskImage);
    
    //出力
    cv::Mat maskedImage;
    src->copyTo(maskedImage, maskImage);
    *dst = maskedImage;
}


int redMoment (cv::Mat* dst, cv::Mat* imgThresholded,
                int iLowH, int iHighH,
                int iLowS, int iHighS,
                int iLowV, int iHighV){
    
    int iLastX = -1;
    int iLastY = -1;
    
    cv::Mat imgHSV;
    
    cvtColor(*dst, imgHSV, COLOR_BGR2HSV); //Convert the captured frame from BGR to HSV
    
    cv::inRange(imgHSV, Scalar(100, 0, 0), Scalar(255, 255, 255), *imgThresholded); //Threshold the image
    
    //morphological opening (removes small objects from the foreground)
    cv::erode(*imgThresholded, *imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
    cv::dilate(*imgThresholded, *imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
    
    //morphological closing (removes small holes from the foreground)
    dilate( *imgThresholded, *imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
    erode(*imgThresholded, *imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
    
    //Calculate the moments of the thresholded image
    Moments oMoments = moments(*imgThresholded);
    
    double dM01 = oMoments.m01;
    double dM10 = oMoments.m10;
    double dArea = oMoments.m00;
    
    // if the area <= 10000, I consider that the there are no object in the image and it's because of the noise, the area is not zero
    if (dArea > 10000)
    {
        //calculate the position of the ball
        int posX = dM10 / dArea;
        int posY = dM01 / dArea;
        
        iLastX = posX;
        iLastY = posY;
        NSLog(@"posX: %d, posY: %d",posX,posY);
        
    }
    return iLastX;
}

@end