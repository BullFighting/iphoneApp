//
//  SendingKonashi.m
//  ImageCaptureSample
//
//  Created by 黒田 優太朗 on 2014/12/14.
//  Copyright (c) 2014年 Olympus Imaging Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFKonashi.h"
#import "Konashi.h"

@implementation  BFKonashi

+(void)pinSend:(int)num{

    switch(num){
        case 1: NSLog(@"左");
            //左旋回
            [Konashi pinModeAll:     0b00011110];
            [Konashi digitalWriteAll:0b00001000];
            break;
        case 2: NSLog(@"前進");
            //全進
            [Konashi pinModeAll:     0b00011110];
            [Konashi digitalWriteAll:0b00001100];
            break;
        case 3: NSLog(@"右");
            //右旋回
            [Konashi pinModeAll:     0b00011110];
            [Konashi digitalWriteAll:0b00000100];
            break;
        case 4: NSLog(@"止める");
            //止める
            [Konashi pinModeAll:     0b00011110];
            [Konashi digitalWriteAll:0b00000000];
            break;
        default:
            break;
    }
}

@end