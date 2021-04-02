//
//  ResampleToSize.m
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 01.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import "ResampleToSize.h"
#import <Accelerate/Accelerate.h>

@implementation ResampleToSize

+ (void)decimating:(const float *)src count:(int)srcCount dst:(float *)dst count:(int)dstCount {
	vDSP_Length filterCount = srcCount / dstCount;

	vDSP_Stride decimation = filterCount;
	float *filter = (float *) malloc(filterCount * sizeof(float));
	float part = 1.0f / (float) filterCount;
	for (int i = 0; i < filterCount; i++)
		filter[i] = part;

	vDSP_desamp(src, decimation, filter, dst, dstCount, filterCount);
	free(filter);
}

@end
