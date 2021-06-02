//
//  WaveformAnalyzer.cpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 01.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#include "WaveformAnalyzer.hpp"

// Adapted from https://github.com/MTG/essentia/blob/867dfa474292e035a27f44a233d0b321d42e5688/src/algorithms/extractor/freesoundextractor.cpp

const string WaveformAnalyzer::nameSpace="waveform.";

void WaveformAnalyzer::runNetwork(Algorithm *loader, Pool& results){
	Real analysisSampleRate = 44100;
	streaming::AlgorithmFactory& factory = streaming::AlgorithmFactory::instance();

	streaming::Algorithm* demuxer = factory.create("StereoDemuxer");
	streaming::Algorithm* muxer = factory.create("StereoMuxer");
	streaming::Algorithm* resampleR = factory.create("Resample");
	streaming::Algorithm* resampleL = factory.create("Resample");
	
	loader->output("audio")      >> demuxer->input("audio");
	demuxer->output("left")      >> resampleL->input("signal");
	demuxer->output("right")     >> resampleR->input("signal");
	resampleR->output("signal")  >> muxer->input("right");
	resampleL->output("signal")  >> muxer->input("left");

	// ================================================
	// Loudness Waveform
	// ================================================

	streaming::Algorithm* loudness = factory.create("LoudnessEBUR128",
													"startAtZero", true);

	Real inputSampleRate = lastTokenProduced<Real>(loader->output("sampleRate"));
	resampleR->configure("inputSampleRate", inputSampleRate,
						 "outputSampleRate", analysisSampleRate);
	resampleL->configure("inputSampleRate", inputSampleRate,
						 "outputSampleRate", analysisSampleRate);

	// TODO implement StereoLoader algorithm instead of hardcoding this chain
	muxer->output("audio")       >> loudness->input("signal");
	loudness->output("integratedLoudness") >> PC(results, "loudness_ebu128.integrated");
	loudness->output("momentaryLoudness") >> PC(results, "loudness_ebu128.momentary");
	loudness->output("shortTermLoudness") >> PC(results, "loudness_ebu128.short_term");
	loudness->output("loudnessRange") >> PC(results, "loudness_ebu128.loudness_range");
	
	// ================================================
	// Run & Post
	// ================================================

	scheduler::Network network(loader);
	network.run();
	
	// set length (actually duration) of the file and length of analyzed segment
	Real length = loader->output("audio").totalProduced() / inputSampleRate;
	Real analysis_length = muxer->output("audio").totalProduced() / analysisSampleRate;

	if (!analysis_length) {
	  ostringstream msg;
	  msg << "FreesoundExtractor: empty input signal (analysis input audio length: " << length << ")";
	  throw EssentiaException(msg);
	}

	results.set("metadata.audio_properties.length", length);
	results.set("metadata.audio_properties.analysis.length", analysis_length);

	// This is just our best guess as to if a file is in a lossless or lossy format
	// It won't protect us against people converting from (e.g.) mp3 -> flac
	// before submitting
	const char* losslessCodecs[] = {"alac", "ape", "flac", "shorten", "tak", "truehd", "tta", "wmalossless"};
	vector<string> lossless = arrayToVector<string>(losslessCodecs);
	const string codec = results.value<string>("metadata.audio_properties.codec");
	bool isLossless = find(lossless.begin(), lossless.end(), codec) != lossless.end();
	if (!isLossless && codec.substr(0, 4) == "pcm_") {
		isLossless = true;
	}
	results.set("metadata.audio_properties.lossless", isLossless);
}
