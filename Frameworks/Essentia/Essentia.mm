//
//  Essentia.m
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 04.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import "Essentia.h"

// TODO No idea what do import lol, but this works
#import "TonalAnalyzer.hpp"

using namespace essentia;

@implementation Essentia

+ (void) initAlgorithms {
	essentia::init();
}

+ (bool) isInitialized {
	return essentia::isInitialized();
}

@end
