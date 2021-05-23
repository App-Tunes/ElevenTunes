//
//  RhythmAnalyzer.hpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 31.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#ifndef RhythmAnalyzer_hpp
#define RhythmAnalyzer_hpp

#include <MusicDescriptorsSet.h>

class RhythmAnalyzer {
public:
	static const string nameSpace;
	
	static void createNetworkLowLevel(SourceBase& source, Pool& pool);
	static void createNetwork(SourceBase& source, Pool& pool);
};

#endif /* RhythmAnalyzer_hpp */
