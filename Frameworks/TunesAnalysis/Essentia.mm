//
//  Essentia.m
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 04.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#import "Essentia.h"

// TODO No idea what do import lol, but this works
#import "algorithmfactory.h"

#import "AVFoundationLoader.hpp"
#import "AVFoundationMonoLoader.hpp"

using namespace essentia;

typedef essentia::streaming::AlgorithmFactory::Registrar<essentia::streaming::AVAudioLoader> AVAudioLoaderRegistrar;
typedef essentia::streaming::AlgorithmFactory::Registrar<essentia::streaming::AVMonoLoader> AVMonoLoaderRegistrar;

@implementation Essentia

+ (void) initAlgorithms {
	if (isInitialized())
		return;
	
	essentia::init();
	AVAudioLoaderRegistrar test;
	AVMonoLoaderRegistrar test3;
}

+ (bool) isInitialized {
	return essentia::isInitialized();
}

@end
