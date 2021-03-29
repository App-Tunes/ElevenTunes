//
//  EssentiaFile.h
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.03.21.
//

#import <Foundation/Foundation.h>
#import "EssentiaAnalysis.h"

NS_ASSUME_NONNULL_BEGIN

@interface EssentiaFile : NSObject

-(instancetype)initWithURL:(NSURL * _Nonnull)url;

@property (readonly, nonnull) NSURL *url;

- (EssentiaAnalysis * _Nullable) analyze: (NSError **)error;

@end

NS_ASSUME_NONNULL_END
