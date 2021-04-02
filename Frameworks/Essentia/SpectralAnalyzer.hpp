//
//  SpectralAnalyzer.hpp
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 02.04.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#ifndef SpectralAnalyzer_hpp
#define SpectralAnalyzer_hpp

#include <MusicDescriptorsSet.h>

class SpectralAnalyzer {
public:
	static const string nameSpace;
	
	static void runNetwork(string filename, Pool& pool);
};

#endif /* SpectralAnalyzer_hpp */
