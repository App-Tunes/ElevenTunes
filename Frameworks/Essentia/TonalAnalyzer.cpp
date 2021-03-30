//
//  TonalAnalyzer.cpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 29.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#include "TonalAnalyzer.hpp"

using namespace std;
using namespace essentia;
using namespace essentia::streaming;

// Adapted from https://github.com/MTG/essentia/blob/6ad4f973ca93ef6fadd83a029e46e4bb70f92726/src/algorithms/extractor/musicextractor.h

const string TonalAnalyzer::nameSpace="tonal.";

void TonalAnalyzer::createNetworkLowLevel(SourceBase& source, Pool& pool) {
	int frameSize = 4096;
	int hopSize =   2048;
	string windowType = "blackmanharris62";
	int zeroPadding = 0;

	AlgorithmFactory& factory = AlgorithmFactory::instance();

	Algorithm* fc     = factory.create("FrameCutter",
									   "frameSize", frameSize,
									   "hopSize", hopSize);
	Algorithm* w      = factory.create("Windowing",
									   "type", windowType,
									   "zeroPadding", zeroPadding);
	Algorithm* spec   = factory.create("Spectrum");
	// TODO: which parameters to select for min/maxFrequency? [20, 3500] for consistency?
	Algorithm* peaks  = factory.create("SpectralPeaks",
									   "maxPeaks", 10000,
									   "magnitudeThreshold", 0.00001,
									   "minFrequency", 40,
									   "maxFrequency", 5000,
									   "orderBy", "frequency");
	Algorithm* tuning = factory.create("TuningFrequency");

	source                            >> fc->input("signal");
	fc->output("frame")               >> w->input("frame");
	w->output("frame")                >> spec->input("frame");
	spec->output("spectrum")          >> peaks->input("spectrum");
	peaks->output("magnitudes")       >> tuning->input("magnitudes");
	peaks->output("frequencies")      >> tuning->input("frequencies");
	tuning->output("tuningFrequency") >> PC(pool, nameSpace + "tuningFrequency");
	tuning->output("tuningCents")     >> NOWHERE;
}

void TonalAnalyzer::createNetwork(SourceBase& source, Pool& pool) {
	int frameSize = 4096;
	int hopSize =   2048;
	string windowType = "blackmanharris62";
	int zeroPadding = 0;

	AlgorithmFactory& factory = AlgorithmFactory::instance();

	Algorithm* fc = factory.create("FrameCutter",
								   "frameSize", frameSize,
								   "hopSize", hopSize);
	Algorithm* w = factory.create("Windowing",
								  "type", windowType,
								  "zeroPadding", zeroPadding);
	Algorithm* spec = factory.create("Spectrum");
	Algorithm* peaks = factory.create("SpectralPeaks",
									  "maxPeaks", 60,
									  "magnitudeThreshold", 0.00001,
									  "minFrequency", 20.0,
									  "maxFrequency", 3500.0,
									  "orderBy", "magnitude");
	// Detecting 60 peaks instead of all of them as it may be better not to
	// consider too many harmonics, especially for electronic music
	
	Real tuningFreq = pool.value<vector<Real> >(nameSpace + "tuningFrequency").back();

	// Using HPCP parameters recommended for electronic music:
	Algorithm* hpcp_key = factory.create("HPCP",
										 "size", 36,
										 "referenceFrequency", tuningFreq,
										 "bandPreset", false,
										 "minFrequency", 20.0,
										 //"bandSplitFrequency", 250.0, // TODO ???
										 "maxFrequency", 3500.0,
										 "weightType", "cosine",
										 "nonLinear", false,
										 "windowSize", 1.);
	// Previously used parameter values:
	// - nonLinear = false
	// - weightType = squaredCosine
	// - windowSize = 4.0/3.0
	// - bandPreset = true

	Algorithm* skey = factory.create("Key",
									 "numHarmonics", 4,
									 "pcpSize", 36,
									 "profileType", "temperley",
									 "slope", 0.6,
									 "usePolyphony", true,
									 "useThreeChords", true);

	// TODO review this parameters to improve our chords detection
	Algorithm* hpcp_chord = factory.create("HPCP",
										   "size", 36,
										   "referenceFrequency", tuningFreq,
										   "harmonics", 8,
										   "bandPreset", true,
										   "minFrequency", 20.0,
										   "maxFrequency", 3500.0,
										   "bandSplitFrequency", 500.0,
										   "weightType", "cosine",
										   "nonLinear", true,
										   "windowSize", 0.5);

	Algorithm* schord = factory.create("ChordsDetection");
	Algorithm* schords_desc = factory.create("ChordsDescriptors");

	source                       >> fc->input("signal");
	fc->output("frame")          >> w->input("frame");
	w->output("frame")           >> spec->input("frame");
	spec->output("spectrum")     >> peaks->input("spectrum");

	peaks->output("frequencies") >> hpcp_key->input("frequencies");
	peaks->output("magnitudes")  >> hpcp_key->input("magnitudes");
	hpcp_key->output("hpcp")     >> PC(pool, nameSpace + "hpcp");
	hpcp_key->output("hpcp")     >> skey->input("pcp");

	skey->output("key")          >> PC(pool, nameSpace + "key.key");
	skey->output("scale")        >> PC(pool, nameSpace + "key.scale");
	skey->output("strength")     >> PC(pool, nameSpace + "key.strength");
	
	peaks->output("frequencies") >> hpcp_chord->input("frequencies");
	peaks->output("magnitudes")  >> hpcp_chord->input("magnitudes");
	hpcp_chord->output("hpcp")   >> schord->input("pcp");
	schord->output("strength")   >> PC(pool, nameSpace + "chords_strength");
	
	// TODO: Chords progression has low practical sense and is based on a very simple algorithm prone to errors.
	// We need to have better algorithm first to include this descriptor.
	// schord->output("chords") >> PC(pool, nameSpace + "chords_progression");
	
	// TODO: chord histogram is aligned so than the first bin is the overall key
	//       estimated using temperley profile. Should we align to the most
	//       frequent chord instead?
	schord->output("chords")					>> schords_desc->input("chords");
	skey->output("key")							>> schords_desc->input("key");
	skey->output("scale")						>> schords_desc->input("scale");
	schords_desc->output("chordsHistogram")		>> PC(pool, nameSpace + "chords_histogram");
	schords_desc->output("chordsNumberRate")	>> PC(pool, nameSpace + "chords_number_rate");
	schords_desc->output("chordsChangesRate")	>> PC(pool, nameSpace + "chords_changes_rate");
	schords_desc->output("chordsKey")			>> PC(pool, nameSpace + "chords_key");
	schords_desc->output("chordsScale")			>> PC(pool, nameSpace + "chords_scale");

	// HPCP Entropy and Crest
	Algorithm* ent = factory.create("Entropy");
	hpcp_chord->output("hpcp")  >> ent->input("array");
	ent->output("entropy")      >> PC(pool, nameSpace + "hpcp_entropy");
	
	Algorithm* crest = factory.create("Crest");
	hpcp_chord->output("hpcp") >> crest->input("array");
	crest->output("crest") >> PC(pool, nameSpace + "hpcp_crest");

	// HPCP Tuning
	Algorithm* hpcp_tuning = factory.create("HPCP",
											"size", 120,
											"referenceFrequency", tuningFreq,
											"harmonics", 8,
											"bandPreset", true,
											"minFrequency", 20.0,
											"maxFrequency", 3500.0,
											"bandSplitFrequency", 500.0,
											"weightType", "cosine",
											"nonLinear", true,
											"windowSize", 0.5);

	peaks->output("frequencies")  >> hpcp_tuning->input("frequencies");
	peaks->output("magnitudes")   >> hpcp_tuning->input("magnitudes");
	hpcp_tuning->output("hpcp")   >> PC(pool, nameSpace + "hpcp_highres");

}
