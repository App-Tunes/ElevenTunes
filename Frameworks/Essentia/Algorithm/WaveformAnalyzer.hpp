//
//  WaveformAnalyzer.hpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 01.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#ifndef WaveformAnalyzer_hpp
#define WaveformAnalyzer_hpp

#include <MusicDescriptorsSet.h>

class WaveformAnalyzer {
public:
	static const string nameSpace;
	
	static void runNetwork(Algorithm* loader, Pool& pool);
};

#endif /* WaveformAnalyzer_hpp */
