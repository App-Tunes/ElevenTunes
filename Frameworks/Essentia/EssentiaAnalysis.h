//
//  EssentiaAnalysis.h
//  Essentia-Tests
//
//  Created by Lukas Tenbrink on 28.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>

NS_ASSUME_NONNULL_BEGIN

@interface EssentiaKeyAnalysis : NSObject

@property (nullable, retain) NSString *key;
@property (nullable, retain) NSString *scale;
@property double tuningFrequency;
@property double strength;

@end

@interface EssentiaRhythmAnalysis : NSObject

@property double bpm;

@end

@interface EssentiaAnalysis : NSObject

@property (nullable, retain) EssentiaKeyAnalysis* keyAnalysis;
@property (nullable, retain) EssentiaRhythmAnalysis* rhythmAnalysis;

@end

@interface EssentiaWaveform : NSObject

@property (readonly)  int count;
@property (readonly) float integratedLoudness;
@property (readonly) float loudnessRange;
@property (readonly) float *loudness;
@property (readonly) float *pitch;

- (instancetype)initWithCount: (int) count integrated: (float) integrated range: (float) range;

@end

NS_ASSUME_NONNULL_END
