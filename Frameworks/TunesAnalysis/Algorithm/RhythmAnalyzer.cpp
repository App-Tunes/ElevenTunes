//
//  RhythmAnalyzer.cpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 31.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#include "RhythmAnalyzer.hpp"

// Adapted from https://github.com/MTG/essentia/blob/867dfa474292e035a27f44a233d0b321d42e5688/src/essentia/utils/extractor_music/MusicRhythmDescriptors.cpp

const string RhythmAnalyzer::nameSpace="rhythm.";

void  RhythmAnalyzer::createNetworkLowLevel(SourceBase& source, Pool& pool){
  
  AlgorithmFactory& factory = AlgorithmFactory::instance();

  // Rhythm extractor
  Algorithm* rhythmExtractor = factory.create("RhythmExtractor2013");
  rhythmExtractor->configure("method", "degara",
							 "maxTempo", (int) 208,
							 "minTempo", (int) 40);

  source                                >> rhythmExtractor->input("signal");
  rhythmExtractor->output("ticks")      >> PC(pool, nameSpace + "beats_position");
  rhythmExtractor->output("bpm")        >> PC(pool, nameSpace + "bpm");
  rhythmExtractor->output("confidence") >> NOWHERE;
  rhythmExtractor->output("estimates")  >> NOWHERE;
  // dummy "confidence" because 'degara' method does not estimate confidence
  // NOTE: we do not need bpm estimates and intervals in the pool because
  //       they can be deduced from ticks position and occupy too much space

  // BPM Histogram descriptors
  Algorithm* bpmhist = factory.create("BpmHistogramDescriptors");
  rhythmExtractor->output("bpmIntervals") >> bpmhist->input("bpmIntervals");

  // connect as single value otherwise PoolAggregator will compute statistics
  connectSingleValue(bpmhist->output("firstPeakBPM"), pool, nameSpace + "bpm_histogram_first_peak_bpm");
  connectSingleValue(bpmhist->output("firstPeakWeight"), pool, nameSpace + "bpm_histogram_first_peak_weight");
  connectSingleValue(bpmhist->output("firstPeakSpread"), pool, nameSpace + "bpm_histogram_first_peak_weight");
  connectSingleValue(bpmhist->output("secondPeakBPM"), pool, nameSpace + "bpm_histogram_second_peak_bpm");
  connectSingleValue(bpmhist->output("secondPeakWeight"), pool, nameSpace + "bpm_histogram_second_peak_weight");
  connectSingleValue(bpmhist->output("secondPeakSpread"), pool, nameSpace + "bpm_histogram_second_peak_spread");
  connectSingleValue(bpmhist->output("histogram"), pool, nameSpace + "bpm_histogram");

  // Onset Detection
  // TODO: use SuperFlux onset rate algorithm instead!
  //       the algorithm that is used is rather outdated, onset times can be
  //       inaccurate, however, onset_rate is still very informative for many
  //       tasks
  Algorithm* onset = factory.create("OnsetRate");
  source                      >> onset->input("signal");
  onset->output("onsetTimes") >> NOWHERE;
  onset->output("onsetRate")  >> PC(pool, nameSpace + "onset_rate");

  // Danceability
  Algorithm* danceability = factory.create("Danceability");
  source                                >> danceability->input("signal");
  danceability->output("danceability")  >> PC(pool, nameSpace + "danceability");
  danceability->output("dfa")           >> NOWHERE;
}

void RhythmAnalyzer::createNetwork(SourceBase& source, Pool& pool){
 
  Real sampleRate = 44100.0;

  AlgorithmFactory& factory = AlgorithmFactory::instance();
  vector<Real> ticks = pool.value<vector<Real> >(nameSpace + "beats_position");
  Algorithm* beatsLoudness = factory.create("BeatsLoudness",
											"sampleRate", sampleRate,
											"beats", ticks);
  source                                      >> beatsLoudness->input("signal");
  beatsLoudness->output("loudness")           >> PC(pool, nameSpace + "beats_loudness");
  beatsLoudness->output("loudnessBandRatio")  >> PC(pool, nameSpace + "beats_loudness_band_ratio");
}
