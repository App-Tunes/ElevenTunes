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

+ (void) decimating: (const float *)src count: (int) srcCount dst: (float *)dst count: (int) dstCount;

@end

NS_ASSUME_NONNULL_END
