//
//  EssentiaAnalysis.m
//  Essentia-Tests
//
//  Created by Lukas Tenbrink on 28.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import "EssentiaAnalysis.h"

@implementation EssentiaKeyAnalysis

@end

@implementation EssentiaRhythmAnalysis

@end

@implementation EssentiaAnalysis

@end

@implementation EssentiaWaveform

- (instancetype)initWithCount: (int) count integrated: (float) integrated range: (float) range {
	self = [super init];
	if (self) {
		_count = count;
		_integratedLoudness = integrated;
		_loudnessRange = range;
		_loudness = (float *) malloc(count * sizeof(float));
		_pitch = (float *) malloc(count * sizeof(float));
	}
	return self;
}

- (void)dealloc {
	if (_loudness) free(_loudness);
	if (_pitch) free(_pitch);
}

@end
