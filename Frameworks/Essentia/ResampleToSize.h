//
//  ResampleToSize.h
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 01.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResampleToSize : NSObject

+ (BOOL) best: (const float *)src count: (int) srcCount dst: (float *)dst count: (int) dstCount error: (NSError **)error;
+ (void) decimating: (const float *)src count: (int) srcCount dst: (float *)dst count: (int) dstCount;
+ (void) secretRabbitCode: (const float *)src count: (int) srcCount dst: (float *)dst count: (int) dstCount quality: (int) quality;

@end

NS_ASSUME_NONNULL_END
