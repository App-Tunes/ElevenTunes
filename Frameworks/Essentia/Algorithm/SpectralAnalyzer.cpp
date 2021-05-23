//
//  SpectralAnalyzer.cpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 02.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#include "SpectralAnalyzer.hpp"

const string SpectralAnalyzer::nameSpace="waveform.";

void SpectralAnalyzer::runNetwork(string filename, Pool& results){
	Real analysisSampleRate = 44100;
	streaming::AlgorithmFactory& factory = streaming::AlgorithmFactory::instance();

	Algorithm* loader = factory.create("AVMonoLoader",
									  "filename", filename);

	streaming::Algorithm* equalLoudness = factory.create("EqualLoudness",
														 "sampleRate", analysisSampleRate);
	streaming::Algorithm* spectralExtrator = factory.create("LowLevelSpectralEqloudExtractor",
															"sampleRate", analysisSampleRate);

	loader->output("audio")          >> equalLoudness->input("signal");
	equalLoudness->output("signal")  >> spectralExtrator->input("signal");

	spectralExtrator->output("dissonance")         >>  PC(results, "spectral.dissonance");
	spectralExtrator->output("sccoeffs")           >>  PC(results, "spectral.sccoeffs");
	spectralExtrator->output("scvalleys")          >>  PC(results, "spectral.scvalleys");
	spectralExtrator->output("spectral_centroid")  >>  PC(results, "spectral.centroid");
	spectralExtrator->output("spectral_kurtosis")  >>  PC(results, "spectral.kurtosis");
	spectralExtrator->output("spectral_skewness")  >>  PC(results, "spectral.skewness");
	spectralExtrator->output("spectral_spread")    >>  PC(results, "spectral.spread");

	scheduler::Network network(loader);
	network.run();
}
