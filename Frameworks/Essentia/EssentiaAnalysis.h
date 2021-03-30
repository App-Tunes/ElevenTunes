//
//  EssentiaAnalysis.h
//  Essentia-Tests
//
//  Created by Lukas Tenbrink on 28.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>

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

NS_ASSUME_NONNULL_END
