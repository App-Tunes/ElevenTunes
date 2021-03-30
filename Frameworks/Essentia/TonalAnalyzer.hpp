//
//  TonalAnalyzer.hpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 29.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#ifndef TonalAnalyzer_hpp
#define TonalAnalyzer_hpp

#include <MusicDescriptorsSet.h>

class TonalAnalyzer {
public:
	static const string nameSpace;
	
	static void createNetworkLowLevel(SourceBase& source, Pool& pool);
	static void createNetwork(SourceBase& source, Pool& pool);
};

#endif /* TonalAnalyzer_hpp */
