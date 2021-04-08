//
//  TagLibFile.mm
//  TenTunes
//
//  Created by Lukas Tenbrink on 30.08.2018.
//  Copyright © 2018 Lukas Tenbrink. All rights reserved.
//

#import "TagLibFile.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
#pragma clang diagnostic ignored "-Weverything"

#import "fileref.h"
#import "tag.h"
#import "tpropertymap.h"

#import "rifffile.h"
#import "aifffile.h"
#import "wavfile.h"
#import "mpegfile.h"
#import "flacfile.h"
#import "trueaudiofile.h"

#import "id3v2tag.h"
#import "id3v2frame.h"
#import "id3v2header.h"
#import "attachedpictureframe.h"
#import "textidentificationframe.h"
#import "commentsframe.h"
#import "mp4tag.h"
//#include "tmap.h"


#import "id3v1tag.h"

#import "iostream"

#import "AVFoundation/AVFoundation.h"

#pragma clang diagnostic pop

inline NSString *TagLibStringToNS(const TagLib::String &tagString) {
    if (tagString == TagLib::ByteVector::null)
        return nil;
    return [NSString stringWithUTF8String:tagString.toCString(true)];
}

inline const TagLib::String TagLibStringFromNS(NSString *string) {
    if (string == nil)
        return TagLib::ByteVector::null;
    return TagLib::String([string UTF8String], TagLib::String::UTF8);
}

#pragma mark File

@interface TagLibFile ()

@property TagLib::FileRef fileRef;

- (TagLib::Tag *)tag;

- (void)setID3:(NSString *)key text:(NSString *)text;

@end

@implementation TagLibFile

-(instancetype)initWithURL:(NSURL * _Nonnull)url {
    self = [super init];
    if (self) {
        TagLib::FileRef f(url.fileSystemRepresentation);
        
        if (f.isNull()) {
            return nil;
        }
        
        [self setFileRef:f];
    }
    return self;
}

- (TagLib::Tag *)tag {
    return _fileRef.tag();
}

#pragma mark Generic

- (void)setTitle:(NSString *)title {
    [self tag]->setTitle(TagLibStringFromNS(title));
}

- (NSString *)title {
    return TagLibStringToNS([self tag]->title());
}

- (void)setArtist:(NSString *)artist {
    [self tag]->setArtist(TagLibStringFromNS(artist));
}

- (NSString *)artist {
    return TagLibStringToNS([self tag]->artist());
}

- (void)setAlbum:(NSString *)album {
    [self tag]->setAlbum(TagLibStringFromNS(album));
}

- (NSString *)album {
    return TagLibStringToNS([self tag]->album());
}

- (void)setBand:(NSString *)band {
    [self setID3:AVMetadataID3MetadataKeyBand text:band];
}

- (NSString *)band {
    return [self getID3v2Text:AVMetadataID3MetadataKeyBand];
}

- (void)setRemixArtist:(NSString *)remixArtist {
    [self setID3:AVMetadataID3MetadataKeyModifiedBy text:remixArtist];
}

- (NSString *)remixArtist {
    return [self getID3v2Text:AVMetadataID3MetadataKeyModifiedBy];
}

- (void)setGenre:(NSString *)genre {
    [self tag]->setGenre(TagLibStringFromNS(genre));
}

- (NSString *)genre {
    return TagLibStringToNS([self tag]->genre());
}

+ (int) priority:(TagLib::ID3v2::AttachedPictureFrame::Type) type {
    switch (type) {
        case TagLib::ID3v2::AttachedPictureFrame::FrontCover:
            return 0;
        case TagLib::ID3v2::AttachedPictureFrame::FileIcon:
            return 1;
        case TagLib::ID3v2::AttachedPictureFrame::OtherFileIcon:
            return 2;
        case TagLib::ID3v2::AttachedPictureFrame::Illustration:
            return 3;
        case TagLib::ID3v2::AttachedPictureFrame::PublisherLogo:
            return 4;
        default:
            return 100;
    }
}

- (void)setImage:(NSData *)image {
    // DON'T remove existing images. Each have different attributes. Only remove the one we're setting
    auto tag = [self id3v2Tag: false];
    if (tag) {
        auto desiredType = TagLib::ID3v2::AttachedPictureFrame::FrontCover;
        
        // Remove old one
        TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
        for(; it != tag->frameList().end(); it++) {
            if(auto picture_frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(*it)) {
                if (picture_frame->type() == desiredType) {
                    tag->removeFrame(picture_frame);
                    break;
                }
            }
        }
        
        // Add new as front cover
        TagLib::ID3v2::AttachedPictureFrame *frame = new TagLib::ID3v2::AttachedPictureFrame();
        frame->setPicture(TagLib::ByteVector((const char *)image.bytes, (unsigned int)image.length));
        frame->setType(desiredType);
        frame->setMimeType("image/jpeg");
        frame->setDescription(TagLibStringFromNS(@"Artwork"));
        frame->setTextEncoding(TagLib::String::Type::UTF8);
        tag->addFrame(frame);
    }
}

- (NSData *)image {
    auto tag = [self id3v2Tag: false];
    if (tag) {
        TagLib::ID3v2::AttachedPictureFrame::Type currentPictureType = TagLib::ID3v2::AttachedPictureFrame::Type::Other;
        NSData *image = nil;
        
        TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
        for(; it != tag->frameList().end(); it++) {
            if(auto picture_frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(*it)) {
                if (image == nil || ([TagLibFile priority: picture_frame->type()] < [TagLibFile priority: currentPictureType])) {
                    
                    TagLib::ByteVector imgVector = picture_frame->picture();
                    image = [NSData dataWithBytes:imgVector.data() length:imgVector.size()];
                    currentPictureType = picture_frame->type();
                }
            }
        }
        
        return image;
    }
    
    return nil;
}

- (void)setInitialKey:(NSString *)initialKey {
    [self setID3:AVMetadataID3MetadataKeyInitialKey text:initialKey];
}

- (NSString *)initialKey {
    return [self getID3v2Text:AVMetadataID3MetadataKeyInitialKey];
}

- (void)setBpm:(NSString *)bpm {
    [self setID3:AVMetadataID3MetadataKeyBeatsPerMinute text:bpm];
}

- (NSString *)bpm {
    return [self getID3v2Text:AVMetadataID3MetadataKeyBeatsPerMinute];
}

- (void)setComments:(NSString *)comments {
    [self tag]->setComment(TagLibStringFromNS(comments));
}
    
- (NSString *)comments {
    return TagLibStringToNS([self tag]->comment());
}

- (void)setPublisher:(NSString *)publisher {
    [self setID3:AVMetadataID3MetadataKeyPublisher text:publisher];
}
    
- (NSString *)publisher {
    return [self getID3v2Text:AVMetadataID3MetadataKeyPublisher];
}

- (void)setYear:(unsigned int)year {
    [self tag]->setYear(year);
}

- (unsigned int)year {
    return [self tag]->year();
}

- (void)setTrackNumber:(unsigned int)trackNumber {
    [self tag]->setTrack(trackNumber);
}

- (unsigned int)trackNumber {
    return [self tag]->track();
}

- (void)setPartOfSet:(NSString *)partOfSet {
    [self setID3:AVMetadataID3MetadataKeyPartOfASet text:partOfSet];
}

- (NSString *)partOfSet {
    return [self getID3v2Text:AVMetadataID3MetadataKeyPartOfASet];
}

// ID3v1 is auto-supported with taglib's default setters and getters
#pragma mark ID3v2
    
- (TagLib::ID3v2::Tag *)id3v2Tag:(BOOL)create {
    // TODO Create
    if (TagLib::MPEG::File *file = dynamic_cast<TagLib::MPEG::File *>(_fileRef.file())) {
        if (file->hasID3v2Tag()) {
            return file->ID3v2Tag();
        }
    }
    else if (TagLib::RIFF::AIFF::File *file = dynamic_cast<TagLib::RIFF::AIFF::File *>(_fileRef.file())) {
        if (file->hasID3v2Tag()) {
			return file->File::tag();
            return file->tag();
        }
    }
    else if (TagLib::RIFF::WAV::File *file = dynamic_cast<TagLib::RIFF::WAV::File *>(_fileRef.file())) {
        if (file->hasID3v2Tag()) {
            return file->ID3v2Tag();
        }
    }
    else if (TagLib::FLAC::File *file = dynamic_cast<TagLib::FLAC::File *>(_fileRef.file())) {
        if (file->hasID3v2Tag()) {
            return file->ID3v2Tag();
        }
    }
    else if (TagLib::TrueAudio::File *file = dynamic_cast<TagLib::TrueAudio::File *>(_fileRef.file())) {
        if (file->hasID3v2Tag()) {
            return file->ID3v2Tag();
        }
    }

    return nil;
}
    
- (NSString *)id3Description {
    auto tag = [self id3v2Tag: false];
    if (tag) {
        NSMutableString *description = [NSMutableString string];
        
        TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
        for(; it != tag->frameList().end(); it++) {
            if(auto text_frame = dynamic_cast<TagLib::ID3v2::TextIdentificationFrame *>(*it)) {
                [description appendFormat:@"%@: %@\n",
                 TagLibStringToNS(text_frame->frameID()), TagLibStringToNS(text_frame->toString())];
            }
        }
        
        return description;
    }
    return nil;
}


- (NSString *)getID3v2Text:(NSString *)key {
    auto tag = [self id3v2Tag: false];
    if (tag) {
        return [TagLibFile getID3TextIn:tag forKey:key];
    }
    return nil;
}

+ (NSString *)getID3TextIn:(TagLib::ID3v2::Tag *)tag forKey:(NSString *)key {
	auto key_str = key.UTF8String;
	
    TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
    for(; it != tag->frameList().end(); it++) {
		auto frame = dynamic_cast<TagLib::ID3v2::Frame *>(*it);
		auto frame_id = frame->frameID();

		if (frame_id != key_str) {
			continue;
		}

		if (auto text_frame = dynamic_cast<TagLib::ID3v2::TextIdentificationFrame *>(frame)) {
			return TagLibStringToNS(text_frame->toString());
		}
		else {
			NSLog(@"Failed to textify frame for key: %@", key);
		}
    }
    
    return nil;
}

- (void)setID3:(NSString *)key text:(NSString *)text {
    auto tag = [self id3v2Tag: true];
    if (tag) {
        [TagLibFile replaceFrameIn:tag key:key text:text];
    }
    else {
        NSLog(@"Failed to create ID3v2 tag for file");
    }
}

+ (void)replaceFrameIn:(TagLib::ID3v2::Tag *)tag key:(NSString *)key text:(NSString *)text {
    // Remove existing
    tag->removeFrames(key.UTF8String);
    
    // Add new
    if (text != nil) {
        TagLib::String tText = TagLibStringFromNS(text);
        TagLib::ID3v2::TextIdentificationFrame *frame = new TagLib::ID3v2::TextIdentificationFrame(key.UTF8String, TagLib::String::UTF8);
        frame->setText(tText);
        tag->addFrame(frame);
    }
}

#pragma mark I/O

-(BOOL)write:(NSError *__autoreleasing *)error {
    if (!_fileRef.save()) {
        @throw [NSException exceptionWithName:@"FileWriteException"
                                       reason:@"File could not be saved"
                                     userInfo:nil];
    }
    
    return YES;
}

@end
