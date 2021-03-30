//
//  EssentiaFile.m
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.03.21.
//

#import "EssentiaFile.h"

#import "NSString+STD.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
#pragma clang diagnostic ignored "-Weverything"

#include "TonalAnalyzer.hpp"
#include "RhythmAnalyzer.hpp"


using namespace std;
using namespace essentia;
using namespace essentia::streaming;

#pragma clang diagnostic pop

@interface EssentiaFile ()

@end

@implementation EssentiaFile

-(instancetype)initWithURL:(NSURL * _Nonnull)url {
	self = [super init];
	if (self) {
		if (!essentia::isInitialized()) {
			essentia::init();
		}
		
		_url = url;
	}
	return self;
}

- (EssentiaAnalysis *)analyze:(NSError *__autoreleasing  _Nullable *)error {
	AlgorithmFactory& factory = AlgorithmFactory::instance();

	string filename = [[[_url absoluteURL] path] STDstring];
	
	try {
		Algorithm* loader = factory.create("MonoLoader",
										  "filename", filename,
										   "downmix", "mix");
		
		// Audio -> FrameCutter
		Pool pool;

		vector<Real> audio;
		TonalAnalyzer::createNetworkLowLevel(loader->output("audio"), pool);
		RhythmAnalyzer::createNetworkLowLevel(loader->output("audio"), pool);
		scheduler::Network network(loader);
		network.run();

		Algorithm* loader_2 = factory.create("MonoLoader",
										  "filename", filename,
										   "downmix", "mix");

		TonalAnalyzer::createNetwork(loader_2->output("audio"), pool);
		RhythmAnalyzer::createNetwork(loader_2->output("audio"), pool);
		scheduler::Network network_2(loader_2);
		network_2.run();

		// ================================================
		// Extract from CPP
		// ================================================

		EssentiaAnalysis *analysis = [[EssentiaAnalysis alloc] init];

		// ---------- Tonal
		
		Real tuningFreq = pool.value<vector<Real> >(TonalAnalyzer::nameSpace + "tuningFrequency").back();
		string key = pool.value<string>(TonalAnalyzer::nameSpace + "key.key");
		string keyScale = pool.value<string>(TonalAnalyzer::nameSpace + "key.scale");
		Real keyStrength = pool.value<Real>(TonalAnalyzer::nameSpace + "key.strength");
		
		EssentiaKeyAnalysis *keyAnalysis = [[EssentiaKeyAnalysis alloc] init];
		[keyAnalysis setKey: [NSString stringWithSTDstring: key]];
		[keyAnalysis setScale: [NSString stringWithSTDstring: keyScale]];
		[keyAnalysis setTuningFrequency: tuningFreq];
		[keyAnalysis setStrength: keyStrength];

		[analysis setKeyAnalysis: keyAnalysis];
		
		// ---------- Rhythm

		Real bpm = pool.value<Real>(RhythmAnalyzer::nameSpace + "bpm");
		
		EssentiaRhythmAnalysis *rhythmAnalysis = [[EssentiaRhythmAnalysis alloc] init];
		[rhythmAnalysis setBpm: bpm];

		[analysis setRhythmAnalysis: rhythmAnalysis];

		return analysis;
	}
	catch (const std::exception& e) {
		*error = [NSError errorWithDomain:@"essentia" code:1 userInfo: @{
			NSLocalizedDescriptionKey: [NSString stringWithSTDstring: e.what()]
		}];
		return nil;
	}
}

@end
