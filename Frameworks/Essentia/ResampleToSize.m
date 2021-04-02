//
//  ResampleToSize.m
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 01.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import "ResampleToSize.h"
#import <Accelerate/Accelerate.h>
#include <samplerate.h>

// From libsamplerate / common.h
#define	SRC_MAX_RATIO			256

@implementation ResampleToSize

+ (void)best:(const float *)src count:(int)srcCount dst:(float *)dst count:(int)dstCount {
	if (srcCount == dstCount) {
		// lol
		memcpy(dst, src, srcCount * sizeof(float));
		return;
	}
	
	float factor = (float) srcCount / (float) dstCount;
	if (factor < SRC_MAX_RATIO && 1 / factor < SRC_MAX_RATIO) {
		[ResampleToSize secretRabbitCode:src count:srcCount dst:dst count:dstCount quality: 1];
	}
	else if (dstCount < srcCount) {
		// This will bulldoze up to 1/256th of the frames, but it's ok.
		[ResampleToSize decimating:src count:srcCount dst:dst count:dstCount];
	}
	else {
		// TODO Strong upsampling, can't deal with this. Accept error?
		exit(1);
	}
}

+ (void)decimating:(const float *)src count:(int)srcCount dst:(float *)dst count:(int)dstCount {
	vDSP_Length filterCount = srcCount / dstCount;

	vDSP_Stride decimation = filterCount;
	float filter[filterCount];
	float part = 1.0f / (float) filterCount;

	vDSP_vfill(&part, filter, 1, filterCount);
	vDSP_desamp(src, decimation, filter, dst, dstCount, filterCount);
}

+ (void)secretRabbitCode:(const float *)srcr count:(int)srcCount dst:(float *)dst count:(int)dstCount quality: (int) quality {
	SRC_DATA src;
	src.input_frames = (long)srcCount;
	src.data_in = srcr;

	src.output_frames = dstCount;
	src.data_out = dst;

	src.src_ratio = (float) dstCount / (float) srcCount;

	// Fill 0, the algorithm might not fill the last few elements
	float zero = 0;
	vDSP_vfill(&zero, dst, 1, dstCount);

	// do the conversion
	int error = src_simple(&src, quality, 1);

	// TODO Not exactly appropriate lol
	if (error)
		exit(error);
}

@end
