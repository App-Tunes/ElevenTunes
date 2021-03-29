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

#include <iostream>
#include <fstream>
#include <algorithmfactory.h>
#include <essentiamath.h>
#include <pool.h>
#include "credit_libav.h"


using namespace essentia;
using namespace essentia::standard;
using namespace std;

#pragma clang diagnostic pop

@interface EssentiaFile ()

@property AlgorithmFactory *factory;

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

		vector<Real> audio;
		loader->output("audio").set(audio);

//		Algorithm* le    = factory.create("LoudnessEBUR128");
//
//		le->input("signal").set(audioBuffer);
//
//		// FrameCutter -> GapsDetector
//		vector<Real> momentaryLoudness, shortTermLoudness;
//		Real integratedLoudness, loudnessRange;
//
//		le->output("momentaryLoudness").set(momentaryLoudness);
//		le->output("shortTermLoudness").set(shortTermLoudness);
//		le->output("integratedLoudness").set(integratedLoudness);
//		le->output("loudnessRange").set(loudnessRange);

		// Key
		
		// Adapted from https://github.com/MTG/essentia/blob/6ad4f973ca93ef6fadd83a029e46e4bb70f92726/src/algorithms/extractor/musicextractor.h#L119
		int frameSize = 4096;
		int hopSize =   2048;
		string windowType = "blackmanharris62";
		int zeroPadding = 0;

		// Adapted from https://github.com/MTG/essentia/blob/master/src/essentia/utils/extractor_music/MusicTonalDescriptors.cpp#L82

		Algorithm* fc = factory.create("FrameCutter",
									   "frameSize", frameSize,
									   "hopSize", hopSize);
		
		vector<Real> frame;
		fc->input("signal").set(audio);
		fc->output("frame").set(frame);

		Algorithm* window = factory.create("Windowing",
									  "type", windowType,
									  "zeroPadding", zeroPadding);
		
		vector<Real> wframe;
		window->input("frame").set(frame);
		window->output("frame").set(wframe);

		Algorithm* spectrum = factory.create("Spectrum");

		vector<Real> spec;
		spectrum->input("frame").set(wframe);
		spectrum->output("spectrum").set(spec);

		// Compute HPCP and key

		// TODO: Tuning frequency is currently provided but not used for HPCP
		// computation, not clear if it would make an improvement for freesound sounds
		Real tuningFreq = 440;
		//Real tuningFreq = pool.value<vector<Real> >(nameSpace + "tuning_frequency").back();

		Algorithm* hpcp_peaks = factory.create("SpectralPeaks",
											   "maxPeaks", 60,
											   "magnitudeThreshold", 0.00001,
											   "minFrequency", 20.0,
											   "maxFrequency", 3500.0,
											   "orderBy", "magnitude");
		// This is taken from MusicExtractor: Detecting 60 peaks instead of all of
		// all peaks may be better, especially for electronic music that has lots of
		// high-frequency content

		vector<Real> frequencies;
		vector<Real> magnitudes;
		hpcp_peaks->input("spectrum").set(spec);
		hpcp_peaks->output("frequencies").set(frequencies);
		hpcp_peaks->output("magnitudes").set(magnitudes);

		Algorithm* hpcp_key = factory.create("HPCP",
											 "size", 36,
											 "referenceFrequency", tuningFreq,
											 "bandPreset", false,
											 "minFrequency", 20.0,
											 "maxFrequency", 3500.0,
											 "weightType", "cosine",
											 "nonLinear", false,
											 "windowSize", 1.);
		// Previously used parameter values:
		// - nonLinear = false
		// - weightType = squaredCosine
		// - windowSize = 4.0/3.0
		// - bandPreset = false
		// - minFrequency = 40
		// - maxFrequency = 5000

		vector<Real> hpcp = vector<Real>(36);
		hpcp_key->input("frequencies").set(frequencies);
		hpcp_key->input("magnitudes").set(magnitudes);
		hpcp_key->output("hpcp").set(hpcp);

		Algorithm* keyAlgorithm = factory.create("Key",
										 "numHarmonics", 4,
										 "pcpSize", 36,
										 "profileType", "temperley",
										 "slope", 0.6,
										 "usePolyphony", true,
										 "useThreeChords", true);

				
		std::string key, keyScale;
		Real keyStrength, firstToSecondStrength;
		keyAlgorithm->input("pcp").set(hpcp);
		keyAlgorithm->output("key").set(key);
		keyAlgorithm->output("scale").set(keyScale);
		keyAlgorithm->output("strength").set(keyStrength);
		keyAlgorithm->output("firstToSecondRelativeStrength").set(firstToSecondStrength);

		/////////// STARTING THE ALGORITHMS //////////////////
		
		loader->compute();
//		le->compute();
		keyAlgorithm->compute();
		
		delete loader;
//		delete le;
		delete keyAlgorithm;

		EssentiaAnalysis *analysis = [[EssentiaAnalysis alloc] init];
		
		EssentiaKeyAnalysis *keyAnalysis = [[EssentiaKeyAnalysis alloc] init];
		[keyAnalysis setKey: [NSString stringWithSTDstring: key]];
		[keyAnalysis setScale: [NSString stringWithSTDstring: keyScale]];
		[keyAnalysis setStrength: keyStrength];
		[keyAnalysis setPrimaryToSecondaryStrength: firstToSecondStrength];

		[analysis setKeyAnalysis: keyAnalysis];
		
		return analysis;
	}
	catch (const std::exception& e) {
		*error = [NSError errorWithDomain:@"essentia" code:1 userInfo: @{
			NSLocalizedDescriptionKey: [NSString stringWithSTDstring: e.what()]
		}];
		// we couldn't feed the world's children...return nil..sniffle...sniffle
		return nil;
	}
}

@end
