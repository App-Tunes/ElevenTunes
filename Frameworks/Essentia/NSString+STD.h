//
//  NSString+STD.h
//  essentia-analysis
//
//  Created by Lukas Tenbrink on 28.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

#ifndef NSString_STD_h
#define NSString_STD_h

#import <string>

// From https://stackoverflow.com/a/7424962/503822

@interface NSString (cppstring_additions)
+(NSString*) stringWithSTDwstring:(const std::wstring&)string;
+(NSString*) stringWithSTDstring:(const std::string&)string;
-(std::wstring) STDwstring;
-(std::string) STDstring;
@end

@implementation NSString (cppstring_additions)

#if TARGET_RT_BIG_ENDIAN
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE);
#else
const NSStringEncoding kEncoding_wchar_t = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE);
#endif

+(NSString*) stringWithSTDwstring:(const std::wstring&)ws
{
	char* data = (char*)ws.data();
	unsigned size = ws.size() * sizeof(wchar_t);

	NSString* result = [[NSString alloc] initWithBytes:data length:size encoding:kEncoding_wchar_t];
	return result;
}

+(NSString*) stringWithSTDstring:(const std::string&)s
{
	return [NSString stringWithUTF8String: s.c_str()];
}

-(std::wstring) STDwstring
{
	NSData* asData = [self dataUsingEncoding: kEncoding_wchar_t];
	return std::wstring((wchar_t*)[asData bytes], [asData length] / sizeof(wchar_t));
}
-(std::string) STDstring
{
	return [self UTF8String];
}

@end


#endif /* NSString_STD_h */
