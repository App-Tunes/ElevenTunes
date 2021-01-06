//
//  BSManagedDocument.m
//
//  Created by Sasmito Adibowo on 29-08-12.
//  Rewritten by Mike Abdullah on 02-11-12.
//  Copyright (c) 2012-2013 Karelia Software, Basil Salad Software. All rights reserved.
//  http://basilsalad.com
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT_s
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "BSManagedDocument.h"

#import <objc/message.h>

NSString* BSManagedDocumentDidSaveNotification = @"BSManagedDocumentDidSaveNotification" ;
NSString* BSManagedDocumentErrorDomain = @"BSManagedDocumentErrorDomain" ;

@interface BSManagedDocument ()

@property(nonatomic, copy) NSURL *autosavedContentsTempDirectoryURL;
@property(atomic, assign) BOOL isSaving;
@property(atomic, assign) BOOL shouldCloseWhenDoneSaving;
@property (atomic, copy) BOOL (^writingBlock)(NSURL*, NSSaveOperationType, NSURL*, NSError**);


@end


@implementation BSManagedDocument

- (void)setWritingBlock:(WritingBlockType)writingBlock {
    if (_writingBlock) {
#if !__has_feature(objc_arc)
        Block_release(_writingBlock);
#endif
    }
    
    if (writingBlock) {
#if !__has_feature(objc_arc)
        _writingBlock = Block_copy(writingBlock);
#else
        _writingBlock = [writingBlock copy];
#endif
    } else {
        _writingBlock = nil;
    }
}

- (WritingBlockType)writingBlock {
    return _writingBlock;
}

#pragma mark UIManagedDocument-inspired methods

+ (NSString *)storeContentName; { return @"StoreContent"; }
+ (NSString *)persistentStoreName; { return @"persistentStore"; }

+ (NSString *)storePathForDocumentPath:(NSString*)path
{
    BOOL isDirectory = YES;
    [NSFileManager.defaultManager fileExistsAtPath:path
                                       isDirectory:&isDirectory];
    /* I added the initialization YES on 20180114 after seeing a runtime
     warning here, sayig that isDirectory had a "Load of value -96,
     which is not a valid value for type 'BOOL' (aka 'signed char')". */
    if (isDirectory)
    {
        /* path is a file package. */
        path = [path stringByAppendingPathComponent:self.storeContentName];
        path = [path stringByAppendingPathComponent:self.persistentStoreName];
    }

    return path;
}

+ (NSString *)documentPathForStorePath:(NSString*)path
                     documentExtension:(NSString*)extension
{
    NSString* answer = nil;
    if ([path.pathExtension isEqualToString:extension])
    {
        answer = path;
    }
    else if ([path.lastPathComponent isEqualToString:self.persistentStoreName]) {
        path = path.stringByDeletingLastPathComponent;
        if ([path.lastPathComponent isEqualToString:self.storeContentName]) {
            path = path.stringByDeletingLastPathComponent;
            if ([path.pathExtension isEqualToString:extension]) {
                answer = path;
            }
        }
    }

    return answer;
}


+ (NSURL *)persistentStoreURLForDocumentURL:(NSURL *)fileURL;
{
    NSString *storeContent = self.storeContentName;
    if (storeContent) fileURL = [fileURL URLByAppendingPathComponent:storeContent];
    
    fileURL = [fileURL URLByAppendingPathComponent:self.persistentStoreName];
    return fileURL;
}

- (NSManagedObjectContext *)managedObjectContext;
{
    if (!_managedObjectContext)
    {
        // Need 10.7+ to support concurrency types
        NSManagedObjectContext *context = [[self.class.managedObjectContextClass alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self setManagedObjectContext:context];
#if ! __has_feature(objc_arc)
        [context release];
#endif
    }
    
    return _managedObjectContext;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
{
    // Setup the rest of the stack for the context
    if (!_coordinator)
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    if (self.hasUndoManager)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self name:nil object:self.undoManager];
        self.undoManager = nil;
    }
    
    void (^setUndoManagerBlock)(void) = ^{
        /* In macOS 10.11 and earler, the newly-initialized `context`
         typically found at this point will have a NSUndoManager.  But in
         macOS 10.12 and later, surprise, it will have nil undo manager.
         https://github.com/karelia/BSManagedDocument/issues/47
         https://github.com/karelia/BSManagedDocument/issues/50
         In either case, this may be not what the developer has specified
         in overriding +undoManagerClass.  So we test… */
        if (context.undoManager.class != self.class.undoManagerClass)
        {
            /* This branch will always execute, *except* in two *edge* cases:
             * Edge Case 1: macOS 10.11 or earlier, and +undoManagerClass is
             overridden to return NSUndoManager, or not overridden.
             * Edge Case 2: macOS 10.12 or later, and +undoManagerClass is
             overridden to return nil. */
            NSUndoManager *undoManager = [[self.class.undoManagerClass alloc] init];
            context.undoManager = undoManager;  // may rightfully be nil
#if !__has_feature(objc_arc)
            [undoManager release];
#endif
        }
        self.undoManager = context.undoManager;
    };

    [context performBlockAndWait:setUndoManagerBlock];
         
    NSManagedObjectContext *parentContext = [[self.class.managedObjectContextClass alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    parentContext.undoManager = nil; // no point in it supporting undo
    parentContext.persistentStoreCoordinator = _coordinator;
        
    context.parentContext = parentContext;

#if !__has_feature(objc_arc)
    [parentContext release];
#endif

#if __has_feature(objc_arc)
    _managedObjectContext = context;
#else
    [context retain];
    [_managedObjectContext release]; _managedObjectContext = context;
#endif

    // See note JK20170624 at end of file
}

// Allow subclasses to have custom managed object contexts or undo managers
+ (Class)managedObjectContextClass; { return [NSManagedObjectContext class]; }
+ (Class)undoManagerClass; {return [NSUndoManager class]; }

- (NSManagedObjectModel *)managedObjectModel;
{
    if (!_managedObjectModel)
    {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[NSBundle.mainBundle]];

#if ! __has_feature(objc_arc)
        [_managedObjectModel retain];
#endif
    }

    return _managedObjectModel;
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)storeURL
                                           ofType:(NSString *)fileType
                               modelConfiguration:(NSString *)configuration
                                     storeOptions:(NSDictionary<NSString *,id> *)storeOptions
                                            error:(NSError **)error_p
{
    /* I was getting a crash on launch, in OS X 10.11, when previously-opened
     document was attempted to be reopened (for "state restoration") by
     -[NSDocumentController reopenDocumentForURL:withContentsOfURL:display:completionHandler:],
     if said document could not be migrated because it was of an unsupported
     previous data model version.  (Yes, this is an edge edge case).
     This happened in two different projects of mine, one ARC, one non-ARC.
     The crashing seemed to be fixed after I introduced the following local
     'error' variable to isolate it from the out NSError**.
     Jerry Krinock 2016-Mar-14. */
    NSError* __block error = nil ;
    // Create a coordinator if necessary, but do not under any circumstances invoke
    // [self managedObjectContext] inside this function. Creating the managedObjectContext
    // requires access to the main thread (deep inside setParentContext:), but the main
    // thread could be blocked by the Version Browser waiting for a reverted document to
    // load, resulting in a deadlock. So we create the coordinator now and add it to
    // the context later, when we know we have access to the main thread.
    if (!_coordinator)
    {
        /* I don't know when this branch ever runs.  In all my testing,
         _coordinator is created within -setManagedObjectContext:.
         I have never seen this branch run. */
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    }
    
    void (^addPersistentStoreBlock)(void) = ^{
        _store = [_coordinator addPersistentStoreWithType:[self persistentStoreTypeForFileType:fileType]
                                            configuration:configuration
                                                      URL:storeURL
                                                  options:storeOptions
                                                    error:&error];
#if ! __has_feature(objc_arc)
        [_store retain];
        [error retain];
#endif
    };
    
    // Adding a persistent store will post a notification. If your app already has an
    // NSObjectController (or subclass) setup to the context, it will react to that notification,
    // on the assumption it's posted on the main thread. That could do some very weird things, so
    // let's make sure the notification is actually posted on the main thread.
    // Also seems to fix the deadlock in https://github.com/karelia/BSManagedDocument/issues/36
    
    /* Comment by Jerry 2019-09-18:  Until today, the code below used
     [_coordinator performBlockAndWait:] if available, which it is in macOS
     10.10 or later.  That caused a problem in macOS 10.15 Beta 8,
     after opting in to asynchronous saving.  I'm not sure which of these two
     factors is responsible, but since I've already done a lot of testing with
     opting in to asynchronous saving, I want to leave it on.
     
     The problem is that sometimes during an auto save, and always, after
     creating a new adocument and saving it for the first time,
     For some reason, when Core Data Concurency Debugging on, I get the famous
     __Multithreading_Violation_AllThatIsLeftToUsIsHonor_ assertion whenver
     a new document is first saved, and one time I saw it when autosaving an
     already open document.  This assertion occurs inside the
     addPersistentStoreBlock above, upon addPersistentStoreWithType:::::.
     Of course, it does not make any sense that this could happen within a
     performBlockAndWait: call, because that is the whole purpose of
     performBlockAndWait:, to prevent these multithreading violations.
     In this class, the psc and the parent moc can and usually do operate in
     different non-main queues when you send -performBlock: or
     -performBlockAndWait:).  I thought that might be the problem, so I tried
     forcing the psc and the parent moc to operate in the same queue, by
     creating the psc within a performBlockAndWait: sent to the parent moc.
     (See debugging code below in this comment.)  It worked as intended,  but
     had no effect on the problem.
     
     Of course it is possible that the multithreading assertion is a false
     alarm, a bug in 10.15 Beta 8, but I do not want to assume that.
     
     The only way I found to fix the problem, implemented below, is to comment
     out the code branch for macOS 10.10 and later, which uses
     -[NSPersistentStoreCoordinator performBlockAndWait:], and instead execute
     the branch for 10.7 - 10.9, which uses instead
     -[NSManagedObjectContext performBlockAndWait:].  Because I need to ship
     this now, I'm leaving it like that at this time.
     
     Maybe I shall revisit this after 10.15 is out of beta. Here is debugging
     code one can use to log the operating queue of the psc and each of the two
     mocs:
     
     __block NSObject* whatever = nil;
     void (^logTheQueueBlock)(void) = ^void(void){
         NSLog(@"Operating thread is %@ %p for %@", [NSThread isMainThread] ? @"main" : @"non-main", [NSThread currentThread], whatever) ;
     };
     whatever = _coordinator;
     [_coordinator performBlockAndWait:logTheQueueBlock];
     whatever = _managedObjectContext.parentContext;
     [_managedObjectContext.parentContext performBlockAndWait:logTheQueueBlock];
     whatever = _managedObjectContext;
     [_managedObjectContext performBlockAndWait:logTheQueueBlock];
     
     Here is another line of debugging code which is handy:
     
     NSLog(@"1 Created moc %p with NSMainQueueConcurrencyType on %@ thread %p", context, [NSThread isMainThread] ? @"main" : @"secondary", [NSThread currentThread]) ;
     
     And now, the fix… */
//    if ([_coordinator respondsToSelector:@selector(performBlockAndWait:)]) {
//        // 10.10 and later
//        [_coordinator performBlockAndWait:addPersistentStoreBlock];
//    } else
    if (_managedObjectContext) {
        // On 10.7 - 10.9, use the context's performBlockAndWait: - BUT ONLY IF THE CONTEXT
        // ALREADY EXISTS. Creating a context on this thread (which self.managedObjectContext
        // will do) can result in a deadlock with the Version Browser.
        [_managedObjectContext performBlockAndWait:addPersistentStoreBlock];
    } else {
        // If the context doesn't exist, then we don't worry about notifications
        // posting on the wrong thread, so just do the work on this thread.
        addPersistentStoreBlock();
    }
#if ! __has_feature(objc_arc)
    [error autorelease];
#endif
    
    if (error && error_p)
    {
        *error_p = error;
    }
    return (_store != nil);
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)storeURL
                                           ofType:(NSString *)fileType
                                            error:(NSError **)error
{
    // On 10.8+, the coordinator whinges but doesn't fail if you leave out NSReadOnlyPersistentStoreOption and the file turns out to be read-only. Supplying a value makes it fail with a (not very helpful) error when the store is read-only
    NSDictionary<NSString *,id> *options = @{
                              NSReadOnlyPersistentStoreOption : @(self.isInViewingMode)
                              };

    return [self configurePersistentStoreCoordinatorForURL:storeURL
                                                    ofType:fileType
                                        modelConfiguration:nil
                                              storeOptions:options
                                                     error:error];
}

- (NSString *)persistentStoreTypeForFileType:(NSString *)fileType { return NSSQLiteStoreType; }

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error; { return YES; }

- (id)additionalContentForURL:(NSURL *)absoluteURL saveOperation:(NSSaveOperationType)saveOperation error:(NSError **)error;
{
    // Need to hand back something so as not to indicate there was an error
    return [NSNull null];
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error;
{
    return YES;
}

#pragma mark Core Data-Specific

- (BOOL)updateMetadataForPersistentStore:(NSPersistentStore *)store error:(NSError **)error;
{
    return YES;
}

#pragma mark Lifecycle

/* The following three methods implement a mechanism which defer any requested
closing of this document until any currently working Save or Save As
operation is completed.
 
 Without this mechanism, if the code in -closeNow is in -close as it was before
 I fixed this, and if -close is invoked while saving is in progress, saving
 may produce the following rather surprising error (with underlying errors):
 
 code 478202 in domain: BSManagedDocumentErrorDomain
 Failed regular writing

 code: 478206 in domain: BSManagedDocumentErrorDomain
 Failed creating package directories

 code: 516 in domain: NSCocoaErrorDomain
 The file “xxx” couldn’t be saved in the folder “yyy” because a file with the
 same name already exists.

 code: 17 in domain: NSPOSIXErrorDomain
 The operation couldn’t be completed. File exists
 
 This occurs because the _store ivar may be set to nil before the code in the
 so-called "worker block" runs.  That code will presume that this must be a new
 document, and the resulting attempt to create new package directories will
 fail because that code (wisely, to prevent data on disk from being
 overwritten) passes withIntermediateDirectories:NO when invoking NSFileManager
 to do these creations.
 
 This mechanism is obviously important if we are, as we do by default, use
 asynchronous saving (see -canAsynchronouslyWriteToURL::), because the error
 will probably occur every time.  But it is also important (maybe even more
 important) otherwise, because in macOS 10.7+, -[NSDocument saveDocument:]
 always returns immediately, even if a subclass has opted *out* of asynchronous
 saving.  Saving is in fact merely "less asynchronous", and the error will
 occur only *sometimes*.
 */

- (void)close
{
    if (self.isSaving) {
        self.shouldCloseWhenDoneSaving = YES;
    }
    else
    {
        [self closeNow];
    }
}

- (void)signalDoneAndMaybeClose
{
    self.isSaving = NO;

    if (self.shouldCloseWhenDoneSaving)
    {
        [self closeNow];

        /* The following probably has no effect, but is for good practice. */
        self.shouldCloseWhenDoneSaving = NO;
    }
}

- (void)closeNow
{
    NSError *error = nil;
    if (![self removePersistentStoreWithError:&error])
        NSLog(@"Unable to remove persistent store before closing: %@", error);
    [super close];
    [self deleteAutosavedContentsTempDirectory];
}

// It's simpler to wrap the whole method in a conditional test rather than using a macro for each line.
#if ! __has_feature(objc_arc)
- (void)dealloc;
{
    [_managedObjectContext release];
    [_managedObjectModel release];
    [_store release];
    [_coordinator release];
    [_autosavedContentsTempDirectoryURL release];
    
    // _additionalContent is unretained so shouldn't be released here
    
    [super dealloc];
}
#endif


#pragma mark Reading Document Data

- (BOOL)removePersistentStoreWithError:(NSError **)outError {
    __block BOOL result = YES;
    __block NSError * error = nil;
    if (!_store)
        return YES;
    
    void (^removePersistentStoreBlock)(void) = ^{
        result = [_coordinator removePersistentStore:_store error:&error];
#if !__has_feature(objc_arc)
        [error retain];
#endif
    };
    
    if ([_coordinator respondsToSelector:@selector(performBlockAndWait:)]) {
        // (10.10 and later)
        [_coordinator performBlockAndWait:removePersistentStoreBlock];
    } else if (_managedObjectContext) {
        // (10.7 - 10.9, and a context already exists)
        // In my testing, HAVE to do the removal using parent's private queue.
        // Otherwise, it deadlocks, trying to acquire a _PFLock
        NSManagedObjectContext *context = _managedObjectContext;
        while (context.parentContext) {
            context = context.parentContext;
        }
        [context performBlockAndWait:removePersistentStoreBlock];
    } else {
        // If there's not an existing context, any thread should be fine
        removePersistentStoreBlock();
    }
#if !__has_feature(objc_arc)
    [error autorelease];
#endif
    
    if (!result) {

        if (outError) {
            *outError = error;
        }
        return NO;
    }
    
#if !__has_feature(objc_arc)
    [_store release];
#endif
    
    _store = nil;
    
    return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    // Preflight the URL
    //  A) If the file happens not to exist for some reason, Core Data unhelpfully gives "invalid file name" as the error. NSURL gives better descriptions
    //  B) When reverting a document, the persistent store will already have been removed by the time we try adding the new one (see below). If adding the new store fails that most likely leaves us stranded with no store, so it's preferable to catch errors before removing the store if possible
    if (![absoluteURL checkResourceIsReachableAndReturnError:outError]) return NO;
    
    
    // If have already read, then this is a revert-type affair, so must reload data from disk
    if (_store)
    {
        if (!NSThread.isMainThread) {
            [NSException raise:NSInternalInconsistencyException format:@"%@: I didn't anticipate reverting on a background thread!", NSStringFromSelector(_cmd)];
        }
        
        // NSPersistentDocument states: "Revert resets the document’s managed object context. Objects are subsequently loaded from the persistent store on demand, as with opening a new document."
        // I've found for atomic stores that -reset only rolls back to the last loaded or saved version of the store; NOT what's actually on disk
        // To force it to re-read from disk, the only solution I've found is removing and re-adding the persistent store
        if (![self removePersistentStoreWithError:outError])
            return NO;
    }
    
    
    // Setup the store
    // If the store happens not to exist, because the document is corrupt or in the wrong format, -configurePersistentStoreCoordinatorForURL:… will create a placeholder file which is likely undesirable! The only way to avoid that that I can see is to preflight the URL. Possible race condition, but not in any truly harmful way
    NSURL *storeURL = [[self class] persistentStoreURLForDocumentURL:absoluteURL];
    if (![storeURL checkResourceIsReachableAndReturnError:outError])
    {
        // The document architecture presents such an error as "file doesn't exist", which makes no sense to the user, so customize it
        if (outError && [*outError code] == NSFileReadNoSuchFileError && [[*outError domain] isEqualToString:NSCocoaErrorDomain])
        {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:@{ NSUnderlyingErrorKey : *outError }];
        }
        
        return NO;
    }
    
    BOOL result = [self configurePersistentStoreCoordinatorForURL:storeURL
                                                           ofType:typeName
                                                            error:outError];
    
    if (result)
    {
        result = [self readAdditionalContentFromURL:absoluteURL error:outError];
    }
    
    return result;
}

/* The following two methods are necessary because in one of the methods below
we use a weak self (`welf`) when compiling with ARC.  We should make these two
 methods properties and replace all of the remaining direct instance variable
 accesses.  They scare me.
 */

- (NSPersistentStore*)store {
    return _store;
}

- (NSPersistentStoreCoordinator*)coordinator {
    return _coordinator;
}

#pragma mark Writing Document Data

- (BOOL)makeWritingBlockForURL:(NSURL *)url ofType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError;
{
    // NSAssert([NSThread isMainThread], @"Somehow -%@ has been called off of the main thread (operation %u to: %@)", NSStringFromSelector(_cmd), (unsigned)saveOperation, [url path]);
    // See Note JK20180125 below.
    
    BOOL __block ok = YES;

    // Grab additional content that a subclass might provide
    if (outError) *outError = nil;  // unusually for me, be forgiving of subclasses which forget to fill in the error
    id additionalContent = [self additionalContentForURL:url saveOperation:saveOperation error:outError];
    if (!additionalContent)
    {
        if (outError) NSAssert(*outError != nil, @"-additionalContentForURL:saveOperation:error: failed with a nil error");
        [self signalDoneAndMaybeClose];
        ok = NO;
    }
    
    
    // On 10.7+, save the main context, ready for parent to be saved in a moment
    /* Jerry says: With Core Data thread checking on, I was getting the
     familiar "All that is left to us is honor" exceptions here when my
     document was saved, on 20180909.  I think this may have started when I
     tried it with asynchronous saving ON for a time.  (That is, I changed my
     subclass' override of -canAsynchronouslyWriteToURL:::: to return YES.)
     Wrapping the call to -save: in -performBlockAndWait:, below, fixed it. */
    NSError* __block blockError = nil;
    NSManagedObjectContext *context = self.managedObjectContext;
    [context performBlockAndWait:^{
        ok = [context save:&blockError];
#if !__has_feature(objc_arc)
        [blockError retain];
#endif
    }];
#if !__has_feature(objc_arc)
    [blockError autorelease];
#endif
    if (outError && blockError) {
        *outError = blockError;
    }
    if (!ok)
    {
        [self signalDoneAndMaybeClose];
        if (outError && !*outError)
        {
            *outError = [NSError errorWithDomain:BSManagedDocumentErrorDomain
                                            code:478221
                                        userInfo:@{ NSLocalizedDescriptionKey : @"Unspecified error saving Core Data MOC" }];
        }
    }
    
#if __has_feature(objc_arc)
    __weak typeof(self) welf = self;
#else
    // __weak was meaningless in non-ARC; generates a compiler warning
    BSManagedDocument* welf = self;
#endif
    
    self.writingBlock = ^(NSURL *url, NSSaveOperationType saveOperation, NSURL *originalContentsURL, NSError **error) {
        
        // For the first save of a document, create the folders on disk before we do anything else
        // Then setup persistent store appropriately
        BOOL result = YES;
        NSURL *storeURL = [welf.class persistentStoreURLForDocumentURL:url];
        
        if (![welf store])
        {
            result = [welf createPackageDirectoriesAtURL:url
                                                  ofType:typeName
                                        forSaveOperation:saveOperation
                                     originalContentsURL:originalContentsURL
                                                   error:error];
            if (!result)
            {
                [welf spliceErrorWithCode:478206
                     localizedDescription:@"Failed creating package directories"
                            likelyCulprit:url
                             intoOutError:error];
                [welf signalDoneAndMaybeClose];
                return NO;
            }
            
            result = [welf configurePersistentStoreCoordinatorForURL:storeURL
                                                              ofType:typeName
                                                               error:error];
            if (!result)
            {
                [welf spliceErrorWithCode:478207
                     localizedDescription:@"Failed to configure PSC"
                            likelyCulprit:storeURL
                             intoOutError:error];
                [welf signalDoneAndMaybeClose];
                return NO;
            }
        }
        else if (saveOperation == NSSaveAsOperation)
        {
            // Copy the whole package to the new location, not just the store content
            if (![welf writeBackupToURL:url error:error])
            {
                [welf spliceErrorWithCode:478208
                     localizedDescription:@"Failed writing backup file"
                            likelyCulprit:url
                             intoOutError:error];
                [welf signalDoneAndMaybeClose];
                return NO;
            }
        }
        else
        {
            if (welf.class.autosavesInPlace)
            {
                if (saveOperation == NSAutosaveElsewhereOperation)
                {
                    // Special-case autosave-elsewhere for 10.7+ documents that have been saved
                    // e.g. reverting a doc that has unautosaved changes
                    // The system asks us to autosave it to some temp location before closing
                    // CAN'T save-in-place to achieve that, since the doc system is expecting us to leave the original doc untouched, ready to load up as the "reverted" version
                    // But the doc system also asks to do this when performing a Save As operation, and choosing to discard unsaved edits to the existing doc. In which case the SQLite store moves out underneath us and we blow up shortly after
                    // Doc system apparently considers it fine to fail at this, since it passes in NULL as the error pointer
                    // With great sadness and wretchedness, that's the best workaround I have for the moment
                    NSURL *fileURL = welf.fileURL;
                    if (fileURL)
                    {
                        NSURL *autosaveURL = welf.autosavedContentsFileURL;
                        if (!autosaveURL)
                        {
                            // Make a copy of the existing doc to a location we control first
                            NSURL *autosaveTempDirectory = [NSFileManager.defaultManager URLForDirectory:NSItemReplacementDirectory
                                                                                                  inDomain:NSUserDomainMask
                                                                                         appropriateForURL:fileURL
                                                                                                    create:YES
                                                                                                     error:error];
                            if (!autosaveTempDirectory) {
                                [welf spliceErrorWithCode:478210
                                     localizedDescription:@"Failed getting IRD"
                                            likelyCulprit:fileURL
                                             intoOutError:error];
                                [welf signalDoneAndMaybeClose];
                                return NO;
                            }
                            welf.autosavedContentsTempDirectoryURL = autosaveTempDirectory;
                            
                            autosaveURL = [autosaveTempDirectory URLByAppendingPathComponent:fileURL.lastPathComponent];
                            if (![welf writeBackupToURL:autosaveURL error:error])
                            {
                                [welf spliceErrorWithCode:478211
                                     localizedDescription:@"Failed writing to backup URL"
                                            likelyCulprit:autosaveURL
                                             intoOutError:error];
                                [welf signalDoneAndMaybeClose];
                                return NO;
                            }
                            
                            welf.autosavedContentsFileURL = autosaveURL;
                        }
                        
                        // Bring the autosaved doc up-to-date
                        NSURL* storeURL = [welf.class persistentStoreURLForDocumentURL:autosaveURL];
                        result = [welf writeStoreContentToURL:storeURL
                                                        error:error];
                        if (!result)
                        {
                            [welf spliceErrorWithCode:478212
                                 localizedDescription:@"Failed writing store content"
                                        likelyCulprit:storeURL
                                         intoOutError:error];
                            [welf signalDoneAndMaybeClose];
                            return NO;
                        }

                        result = [welf writeAdditionalContent:additionalContent
                                                        toURL:autosaveURL
                                          originalContentsURL:originalContentsURL
                                                        error:error];
                        if (!result)
                        {
                            [welf spliceErrorWithCode:478213
                                 localizedDescription:@"Failed writing additional content"
                                        likelyCulprit:autosaveURL
                                         intoOutError:error];
                            [welf signalDoneAndMaybeClose];
                            return NO;
                        }
                        
                        
                        // Then copy that across to the final URL
                        result = [self writeBackupToURL:url error:error];
                        if (!result)
                        {
                            [welf spliceErrorWithCode:478214
                                 localizedDescription:@"Failed copying to final URL"
                                        likelyCulprit:url
                                         intoOutError:error];
                            [welf signalDoneAndMaybeClose];
                            return NO;
                        }
                    }
                }
            }
            else
            {
                if (saveOperation != NSSaveOperation && saveOperation != NSAutosaveInPlaceOperation)
                {
                    if (![storeURL checkResourceIsReachableAndReturnError:NULL])
                    {
                        result = [welf createPackageDirectoriesAtURL:url
                                                              ofType:typeName
                                                    forSaveOperation:saveOperation
                                                 originalContentsURL:originalContentsURL
                                                               error:error];
                        if (!result)
                        {
                            [welf spliceErrorWithCode:478215
                                 localizedDescription:@"Failed creating package directories for non-regular save"
                                        likelyCulprit:url
                                         intoOutError:error];
                            [welf signalDoneAndMaybeClose];
                            return NO;
                        }

                        // Fake a placeholder file ready for the store to save over
                        result = [[NSData data] writeToURL:storeURL options:0 error:error];
                        if (!result)
                        {
                            [welf spliceErrorWithCode:478216
                                 localizedDescription:@"Failed faking placeholder"
                                        likelyCulprit:storeURL
                                         intoOutError:error];
                            [welf signalDoneAndMaybeClose];
                            return NO;
                        }
                    }
                }
            }
        }
        
        // Right, let's get on with it!
        if (![welf writeStoreContentToURL:storeURL error:error])
        {
            [welf signalDoneAndMaybeClose];
            return NO;
        }
        
        result = [welf writeAdditionalContent:additionalContent toURL:url originalContentsURL:originalContentsURL error:error];
        if (result)
        {
            // Update package's mod date. Two circumstances where this is needed:
            //  user requests a save when there's no changes; SQLite store doesn't bother to touch the disk in which case
            //  saving where +storeContentName is non-nil; that folder's mod date updates, but the overall package needs prompting
            // Seems simplest to just apply this logic all the time
            NSError *error;
            if (![url setResourceValue:[NSDate date] forKey:NSURLContentModificationDateKey error:&error])
            {
                NSLog(@"Updating package mod date failed: %@", error);  // not critical, so just log it
            }
        }
        else
        {
            [welf spliceErrorWithCode:478217
                 localizedDescription:@"Failed to get on with writing"
                        likelyCulprit:url
                         intoOutError:error];
            [welf signalDoneAndMaybeClose];
            return NO;
        }
        
        // Restore persistent store URL after Save To-type operations. Even if save failed (just to be on the safe side)
        if (saveOperation == NSSaveToOperation)
        {
            if (![[welf coordinator] setURL:originalContentsURL forPersistentStore:[welf store]])
            {
                NSLog(@"Failed to reset store URL after Save To Operation");
            }
        }
        
        [welf signalDoneAndMaybeClose];
        return result;
    };
    
    return ok;
}

- (BOOL)createPackageDirectoriesAtURL:(NSURL *)url
                               ofType:(NSString *)typeName
                     forSaveOperation:(NSSaveOperationType)saveOperation
                  originalContentsURL:(NSURL *)originalContentsURL
                                error:(NSError **)error;
{
    // Create overall package
    NSDictionary *attributes = [self fileAttributesToWriteToURL:url
                                                         ofType:typeName
                                               forSaveOperation:saveOperation
                                            originalContentsURL:originalContentsURL
                                                          error:error];
    if (!attributes) return NO;
    
    BOOL result = NO;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    result = [fileManager createDirectoryAtURL:url
                   withIntermediateDirectories:NO
                                    attributes:attributes
                                         error:error];
    if (!result)
    {
        [self spliceErrorWithCode:478219
             localizedDescription:@"File Manager failed to create package directory"
                    likelyCulprit:url
                     intoOutError:error];
        return NO;
    }

    // Create store content folder too
    NSString *storeContent = self.class.storeContentName;
    if (storeContent)
    {
        NSURL *storeContentURL = [url URLByAppendingPathComponent:storeContent];
        result = [fileManager createDirectoryAtURL:storeContentURL
                       withIntermediateDirectories:NO
                                        attributes:attributes
                                             error:error];

        if (!result)
        {
            [self spliceErrorWithCode:478218
                 localizedDescription:@"File Manager failed to create store content subdirectory"
                        likelyCulprit:storeContentURL
                         intoOutError:error];
            return NO;
        }
    }
    
    // Set the bundle bit for good measure, so that docs won't appear as folders on Macs without your app installed. Don't care if it fails
    [self setBundleBitForDirectoryAtURL:url];
    
    return YES;
}

- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler
{
    // Can't touch _additionalContent etc. until existing save has finished
    // At first glance, -performActivityWithSynchronousWaiting:usingBlock: seems the right way to do that. But turns out:
    //  * super is documented to use -performAsynchronousFileAccessUsingBlock: internally
    //  * Autosaving (as tested on 10.7) is declared to the system as *file access*, rather than an *activity*, so a regular save won't block the UI waiting for autosave to finish
    //  * If autosaving while quitting, calling -performActivity… here results in deadlock
    [self performAsynchronousFileAccessUsingBlock:^(void (^fileAccessCompletionHandler)(void)) {  // Note StackPoint2

        NSError* shouldAbortError = nil;
        
        if (self.writingBlock != nil) {
            NSLog(@"Warning 382-6733 Aborting save because another is already in progress.");
            shouldAbortError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                   code:NSUserCancelledError
                                               userInfo:nil];
        } else {
            [self makeWritingBlockForURL:url ofType:typeName saveOperation:saveOperation error:&shouldAbortError];

            BOOL notLoaded = [NSDocumentController.sharedDocumentController.documents indexOfObject:self] == NSNotFound;
            if (notLoaded) {
                NSLog(@"Warning 382-6734 Aborting save cuz not loaded: %@", self);
                /* I have seen this occur if a document save is attempted during
                 document opening, as for example if if document opening includes
                 some kind of integrity check which fixes problems.  If such a
                 too-early save is allowed tp proceed here, the call below to
                 [super saveToURL:ofType:forSaveOperation:completionHandler:] will
                 hang with the following stack:

                 #0    0x00007fff7bdd3266 in semaphore_wait_trap ()
                 #1    0x00007fff7bc51bd9 in _dispatch_sema4_wait ()
                 #2    0x00007fff7bc523a0 in _dispatch_semaphore_wait_slow ()
                 #3    0x00007fff5158b756 in -[NSFileCoordinator(NSPrivate) _blockOnAccessClaim:withAccessArbiter:] ()
                 #4    0x00007fff517512f0 in -[NSFileCoordinator(NSPrivate) _coordinateReadingItemAtURL:options:writingItemAtURL:options:error:byAccessor:] ()
                 #5    0x00007fff4d3873cc in -[NSDocument(NSDocumentSaving) _fileCoordinator:coordinateReadingContentsAndWritingItemAtURL:byAccessor:] ()
                 #6    0x00007fff4d389098 in __85-[NSDocument(NSDocumentSaving) _saveToURL:ofType:forSaveOperation:completionHandler:]_block_invoke_2.810 ()
                 #7    0x00007fff4d388844 in __85-[NSDocument(NSDocumentSaving) _saveToURL:ofType:forSaveOperation:completionHandler:]_block_invoke ()
                 #8    0x00007fff4d3886c7 in -[NSDocument(NSDocumentSaving) _saveToURL:ofType:forSaveOperation:completionHandler:] ()
                 #9    0x00000001062bd7c1 in __73-[BSManagedDocument saveToURL:ofType:forSaveOperation:completionHandler:]_block_invoke at // Note StackPoint1
                 #10    0x00007fff4cea138d in -[NSDocument(NSDocumentSerializationAPIs) continueFileAccessUsingBlock:] ()
                 #11    0x00007fff4cea1ab6 in -[NSDocument(NSDocumentSerializationAPIs) _performFileAccess:] ()
                 #12    0x00000001062bd52d in -[BSManagedDocument saveToURL:ofType:forSaveOperation:completionHandler:] at // Note StackPoint2

                 Looks like a file coordination deadlock.  I found that, duing such
                 an attempted save, the document is oddly not in the document
                 controller's documents yet; hence the condition `notLoaded`.
                 */
            }
            BOOL noWritingBlock = (self.writingBlock == nil);
            if (noWritingBlock) {
                NSLog(@"Warning 382-6735 Aborting save cuz no writingBlock: %@", self);
            }

            if (noWritingBlock || notLoaded)
            {
                // In either of these exceptional cases, abort the save.

                // The docs say "be sure to invoke super", but by my understanding it's fine not to if it's because of a failure, as the filesystem hasn't been touched yet.
                self.writingBlock = nil;
                if (!shouldAbortError) {
                    shouldAbortError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                           code:NSUserCancelledError
                                                       userInfo:nil];
                }
            }
        }
            
        if (shouldAbortError) {
            if (NSThread.isMainThread)
            {
                fileAccessCompletionHandler();
                if (completionHandler) completionHandler(shouldAbortError);
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    fileAccessCompletionHandler();
                    if (completionHandler) completionHandler(shouldAbortError);
                });
            }
            return;
        }
        
        // Kick off async saving work
        [super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error) {  // Note StackPoint1
            
            // If the save failed, it might be an error the user can recover from.
            // e.g. the dreaded "file modified by another application"
            // NSDocument handles this by presenting the error, which includes recovery options
            // If the user does choose to Save Anyway, the doc system leaps straight onto secondary thread to
            // accomplish it, without calling this method again.
            // Thus we want to hang onto _writingBlock until the overall save operation is finished, rather than
            // just this method. The best way I can see to do that is to make the cleanup its own activity, so
            // it runs after the end of the current one. Unfortunately there's no guarantee anyone's been
            // thoughtful enough to register this as an activity (autosave, I'm looking at you), so only rely
            // on it if there actually is a recoverable error
            if (error.recoveryAttempter)
            {
                [self performActivityWithSynchronousWaiting:NO usingBlock:^(void (^activityCompletionHandler)(void)) {
                    
                    self.writingBlock = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        activityCompletionHandler();
                    });
                }];
            }
            else
            {
                self.writingBlock = nil;
            }
            
            
            // Clean up our custom autosaved contents directory if appropriate
            if (!error &&
                (saveOperation == NSSaveOperation || saveOperation == NSAutosaveInPlaceOperation || saveOperation == NSSaveAsOperation))
            {
                [self deleteAutosavedContentsTempDirectory];
            }
            
            // And can finally declare we're done
            if (NSThread.isMainThread)
            {
                fileAccessCompletionHandler();
                if (completionHandler) completionHandler(error);
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    fileAccessCompletionHandler();
                    if (completionHandler) completionHandler(error);
                });
            }
        }];
    }];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101300
/* Documentation says that this method was deprecated in macOS 10.7, but I did
 not get any compiler warnings until compiling with 10.13 SDK.  Oh, well; the
 above #if is to avoid the warning. */
- (BOOL)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError;
{
    BOOL result = [super saveToURL:url ofType:typeName forSaveOperation:saveOperation error:outError];
    
    if (result &&
        (saveOperation == NSSaveOperation || saveOperation == NSAutosaveInPlaceOperation || saveOperation == NSSaveAsOperation))
    {
        [self deleteAutosavedContentsTempDirectory];
    }
    
    return result;
}
#endif

- (BOOL)spliceErrorWithCode:(NSInteger)code
       localizedDescription:(NSString*)localizedDescription
              likelyCulprit:(id)likelyCulprit
               intoOutError:(NSError**)outError
{
    if (outError)
    {
        NSMutableDictionary<NSErrorUserInfoKey, id> *mutant = [NSMutableDictionary new];
        mutant[NSLocalizedDescriptionKey] = localizedDescription;
        if (*outError)
        {
            mutant[NSUnderlyingErrorKey] = *outError;
            mutant[@"Likely Culprit"] = likelyCulprit;
        }
        NSDictionary<NSErrorUserInfoKey, id> *userInfo = [mutant copy];
        NSError* overlyingError = [NSError errorWithDomain:BSManagedDocumentErrorDomain
                                                      code:code
                                                  userInfo:userInfo];
        *outError = overlyingError;
#if ! __has_feature(objc_arc)
        [mutant release];
        [userInfo release];
#endif
    }
    
    return YES;  // Silence stupid compiler warning
}


/*    Regular Save operations can write directly to the existing document since Core Data provides atomicity for us
 */
- (BOOL)writeSafelyToURL:(NSURL *)absoluteURL
                  ofType:(NSString *)typeName
        forSaveOperation:(NSSaveOperationType)saveOperation
                   error:(NSError **)outError
{
    BOOL result = NO ;
    BOOL done = NO ;

    // It's possible subclassers support more file types than the Core Data package-based one
    // BSManagedDocument supplies. e.g. an alternative format for exporting, say. If so, they don't
    // want our custom logic kicking in when writing it, so test for that as best we can.
    // https://github.com/karelia/BSManagedDocument/issues/36#issuecomment-91773320
    if ([NSWorkspace.sharedWorkspace type:self.fileType conformsToType:typeName]) {
        
        // At this point, we've either captured all document content, or are writing on the main thread, so it's fine to unblock the UI
        [self unblockUserInteraction];
        
        if (saveOperation == NSSaveOperation || saveOperation == NSAutosaveInPlaceOperation ||
            (saveOperation == NSAutosaveElsewhereOperation && [absoluteURL isEqual:self.autosavedContentsFileURL]))
        {
            NSURL *backupURL = nil;
            
            // As of 10.8, need to make a backup of the document when saving in-place
            if ((saveOperation == NSSaveOperation || saveOperation == NSAutosaveInPlaceOperation) &&
                self.class.preservesVersions)            // otherwise backupURL has a different meaning
            {
                backupURL = self.backupFileURL;
                if (backupURL)
                {
                    if (![self writeBackupToURL:backupURL error:outError])
                    {
                        // If backup fails, seems it's our responsibility to clean up
                        NSError *error;
                        if (![NSFileManager.defaultManager removeItemAtURL:backupURL error:&error])
                        {
                            NSLog(@"Unable to cleanup after failed backup: %@", error);
                        }
                        
                        [self spliceErrorWithCode:478201
                             localizedDescription:@"Failed writing backup prior to writing"
                                    likelyCulprit:backupURL
                                     intoOutError:outError];

                        return NO;
                    }
                }
            }
            
            
            // NSDocument attempts to write a copy of the document out at a temporary location.
            // Core Data cannot support this, so we override it to save directly.
            // The following call is synchronous.  It does not return until
            // saving ia all done
            result = [self writeToURL:absoluteURL
                               ofType:typeName
                     forSaveOperation:saveOperation
                  originalContentsURL:self.fileURL
                                error:outError];
            
            if (!result)
            {
                [self spliceErrorWithCode:478202
                     localizedDescription:@"Failed regular writing"
                            likelyCulprit:absoluteURL
                             intoOutError:outError];

                // Clean up backup if one was made
                // If the failure was actualy NSUserCancelledError thanks to
                // autosaving being implicitly cancellable and a subclass deciding
                // to bail out, this HAS to be done otherwise the doc system will
                // weirdly complain that a file by the same name already exists
                if (backupURL)
                {
                    NSError *error;
                    if (![NSFileManager.defaultManager removeItemAtURL:backupURL error:&error])
                    {
                        NSLog(@"Unable to remove backup after failed write: %@", error);
                    }
                }
                
                // The -write… method maybe wasn't to know that it's writing to the live document, so might have modified it. #179730
                // We can patch up a bit by updating modification date so user doesn't get baffling document-edited warnings again!
                NSDate *modDate;
                if ([absoluteURL getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:NULL])
                {
                    if (modDate)    // some file systems don't support mod date
                    {
                        self.fileModificationDate = modDate;
                    }
                }
            }
            
            done = YES;
        }
    }
    
    if (!done) {
        // Other situations are basically fine to go through the regular channels
        result = [super writeSafelyToURL:absoluteURL
                                  ofType:typeName
                        forSaveOperation:saveOperation
                                   error:outError];
        if (!result) {
            [self spliceErrorWithCode:478203
                 localizedDescription:@"Failed other writing"
                        likelyCulprit:absoluteURL
                        intoOutError:outError];
        }
    }
    
    if (result) {
        NSNotification* note = [[NSNotification alloc] initWithName:BSManagedDocumentDidSaveNotification
                                                             object:self
                                                           userInfo:nil] ;
        [NSNotificationCenter.defaultCenter performSelectorOnMainThread:@selector(postNotification:)
                                                             withObject:note
                                                          waitUntilDone:NO] ;
#if ! __has_feature(objc_arc)
        [note release];
#endif
                                                            
    }
    
    return result ;
}

- (BOOL)writeBackupToURL:(NSURL *)backupURL error:(NSError **)outError;
{
    NSURL *source = self.mostRecentlySavedFileURL;

    BOOL ok;
    /* In case the user inadvertently clicks File > Duplicate on a new
     document which has not been saved yet, source will be nil, so
     we check for that to avoid a subsequent NSFileManager exception. */
    if (source)
    {
        /* The following also copies any additional content in the package. */
        ok = [NSFileManager.defaultManager copyItemAtURL:source toURL:backupURL error:outError];
    }
    else
    {
        ok = YES;
    }

    return ok;
}

- (BOOL)writeToURL:(NSURL *)inURL
            ofType:(NSString *)typeName
  forSaveOperation:(NSSaveOperationType)saveOp
originalContentsURL:(NSURL *)originalContentsURL
             error:(NSError **)outError
{
    if (!self.writingBlock)
    {
        /* We are being called for the first time in the current write
         operation. */
        if (![self makeWritingBlockForURL:inURL ofType:typeName saveOperation:saveOp error:outError]) {
            [self spliceErrorWithCode:478204
                 localizedDescription:@"Failed making _writingBlock"
                        likelyCulprit:inURL
                         intoOutError:outError];
            return NO;
        }
        
        /* The following apparently recursive call to ourself will only occur
         once, because self.writingBlock is no longer nil and the branch in
         which we are now in will not execute in the sequel. */
        BOOL result = [self writeToURL:inURL ofType:typeName forSaveOperation:saveOp originalContentsURL:originalContentsURL error:outError];
        if (!result) {
            [self spliceErrorWithCode:478205
                 localizedDescription:@"Failed writing for real"
                         likelyCulprit:inURL
                         intoOutError:outError];
        }
        
        /* The self.writingBlock has executed and is no longer needed.
         Furthermore, we must clear it to nil in preparation for any subsequent
         write operation. */
        self.writingBlock = nil;
        return result;
    }
    
    // The following invocation of _writingBlock does the actual work of saving
    BOOL ok = self.writingBlock(inURL, saveOp, originalContentsURL, outError);
    return ok;
}

- (void)setBundleBitForDirectoryAtURL:(NSURL *)url;
{
    NSError *error;
    if (![url setResourceValue:@YES forKey:NSURLIsPackageKey error:&error])
    {
        NSLog(@"Error marking document as a package: %@", error);
    }
}

- (BOOL)writeStoreContentToURL:(NSURL *)storeURL error:(NSError **)error;
{
    // First update metadata
    __block BOOL result = [self updateMetadataForPersistentStore:_store error:error];
    if (!result) return NO;
    
    // On 10.7+ we have to work on the context's private queue
    [self unblockUserInteraction];
    return [self preflightURL:storeURL thenSaveContext:self.managedObjectContext.parentContext error:error];
}

- (BOOL)preflightURL:(NSURL *)storeURL thenSaveContext:(NSManagedObjectContext *)context error:(NSError **)error;
{
    // Preflight the save since it tends to crash upon failure pre-Mountain Lion. rdar://problem/10609036
    NSNumber *writable = nil;
    if (![storeURL getResourceValue:&writable forKey:NSURLIsWritableKey error:error])
        return NO;
    
    if (writable.boolValue)
    {
        // Ensure store is saving to right location
        if ([_coordinator setURL:storeURL forPersistentStore:_store])
        {
            __block BOOL result = NO;
            [context performBlockAndWait:^{
                result = [context save:error];
                    
#if ! __has_feature(objc_arc)
                // Errors need special handling to guarantee surviving crossing the block. http://www.mikeabdullah.net/cross-thread-error-passing.html
                if (!result && error) [*error retain];
#endif
            }];
                
#if ! __has_feature(objc_arc)
            if (!result && error) [*error autorelease]; // tidy up since any error was retained on worker thread
#endif
            return result;
        }
    }
    
    if (error)
    {
        // Generic error. Doc/error system takes care of supplying a nice generic message to go with it
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    }
    
    return NO;
}

#pragma mark NSDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName { return YES; }

- (BOOL)isEntireFileLoaded { return NO; }

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation;
{
    return [NSDocument instancesRespondToSelector:_cmd];    // opt in on 10.7+
}

- (void)setFileURL:(NSURL *)absoluteURL
{
    // Mark persistent store as moved
    if (!self.autosavedContentsFileURL)
    {
        [self setURLForPersistentStoreUsingFileURL:absoluteURL];
    }
    
    [super setFileURL:absoluteURL];
}

- (void)setURLForPersistentStoreUsingFileURL:(NSURL *)absoluteURL;
{
    if (!_store) return;
    
    NSURL *storeURL = [[self class] persistentStoreURLForDocumentURL:absoluteURL];
    
    if (![_coordinator setURL:storeURL forPersistentStore:_store])
    {
        NSLog(@"Unable to set store URL");
    }
}

#pragma mark Autosave

/*  Enable autosave-in-place and versions browser on 10.7+
 */
+ (BOOL)autosavesInPlace { return [NSDocument respondsToSelector:_cmd]; }
+ (BOOL)preservesVersions { return self.autosavesInPlace; }

- (void)setAutosavedContentsFileURL:(NSURL *)absoluteURL;
{
    [super setAutosavedContentsFileURL:absoluteURL];
    
    // Point the store towards the most recent known URL
    absoluteURL = self.mostRecentlySavedFileURL;
    if (absoluteURL) [self setURLForPersistentStoreUsingFileURL:absoluteURL];
}

- (NSURL *)mostRecentlySavedFileURL;
{
    // Before the user chooses where to place a new document, it has an autosaved URL only
    // On 10.6-, autosaves save newer versions of the document *separate* from the original doc
    NSURL *result = self.autosavedContentsFileURL;
    if (!result) result = self.fileURL;
    return result;
}

/*
 When asked to autosave an existing doc elsewhere, we do so via an
 intermedate, temporary copy of the doc. This code tracks that temp folder
 so it can be deleted when no longer in use.
 */

@synthesize autosavedContentsTempDirectoryURL = _autosavedContentsTempDirectoryURL;

- (void)deleteAutosavedContentsTempDirectory;
{
    NSURL *autosaveTempDir = self.autosavedContentsTempDirectoryURL;
    if (autosaveTempDir)
    {
#if ! __has_feature(objc_arc)
        [[autosaveTempDir retain] autorelease];
#endif
        self.autosavedContentsTempDirectoryURL = nil;
        
        NSError *error;
        if (![NSFileManager.defaultManager removeItemAtURL:autosaveTempDir error:&error])
        {
            NSLog(@"Unable to remove temporary directory: %@", error);
        }
    }
}

- (IBAction)saveDocument:(id)sender {
    self.isSaving = YES;
    [super saveDocument:sender];
}


#pragma mark Reverting Documents

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
    // Tear down old windows. Wrap in an autorelease pool to get us much torn down before the reversion as we can
    @autoreleasepool
    {
    NSArray<NSWindowController *> *controllers = [self.windowControllers copy]; // we're sometimes handed underlying mutable array. #156271
    for (NSWindowController *aController in controllers)
    {
        [self removeWindowController:aController];
        [aController close];
    }
#if ! __has_feature(objc_arc)
    [controllers release];
#endif
    }


    @try
    {
        if (![super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]) return NO;
        [self deleteAutosavedContentsTempDirectory];
        
        return YES;
    }
    @finally
    {
        [self makeWindowControllers];
        
        // Don't show the new windows if in the middle of reverting due to the user closing document
        // and choosing to revert changes. The new window bouncing on screen looks wrong, and then
        // stops the document closing properly (or at least appearing to have closed).
        // In theory I could not bother recreating the window controllers either. But the document
        // system seems to have the expectation that it can keep your document instance around in
        // memory after the revert-and-close, ready to re-use later (e.g. the user asks to open the
        // doc again). If that happens, the window controllers need to still exist, ready to be
        // shown.
        if (!_closing) [self showWindows];
    }
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
    // Track if in the middle of closing
    _closing = YES;
    
    void (^completionHandler)(BOOL) = ^(BOOL shouldClose) {
        if (delegate) {
            /* Calls to objc_msgSend()  won't compile, by default, or projects
             "upgraded" by Xcode 8-9, due to fact that Build Setting
             "Enable strict checking of objc_msgSend Calls" is now ON.  See
             https://stackoverflow.com/questions/24922913/too-many-arguments-to-function-call-expected-0-have-3
             The result is, oddly, a Semantic Issue:
             "Too many arguments to function call, expected 0, have 5"
             I chose the answer by Sahil Kapoor, which allows me to leave
             the Build Setting ON and not fight with future Xcode updates. */
            id (*typed_msgSend)(id, SEL, id, BOOL, void*) = (void *)objc_msgSend;
            typed_msgSend(delegate, shouldCloseSelector, self, shouldClose, contextInfo);
        }
    };
    
    /*
     There may be a bug near here, or it may be in Veris 7:
     Click in menu: File > New Subject.
     Click the red 'Close' button.
     Next line will deadlock.
     Sending [self setChangeCount:NSChangeCleared] before that line does not help.
     To get rid of such a document (which will reappear on any subsequent launch
     due to state restoration), send here [self close].
     */
    [super canCloseDocumentWithDelegate:self
                    shouldCloseSelector:@selector(document:didDecideToClose:contextInfo:)
                            contextInfo:Block_copy((__bridge void *)completionHandler)];
}

- (void)document:(NSDocument *)document didDecideToClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
    _closing = NO;
    
    // Pass on to original delegate
    void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))(contextInfo);
    completionHandler(shouldClose);
    Block_release(contextInfo);
}

#pragma mark Duplicating Documents

- (NSDocument *)duplicateAndReturnError:(NSError **)outError;
{
    if (outError) {
        *outError = nil;
    }
    /* The above is needed to prevent a up-stack crash in
     -spliceErrorWithCode:localizedDescription:likelyCulprit:intoOutError:
     because, apparently macOS passes *outError = garbage (but, oddly, only
     with ARC in macOS 10.15.)  Anyhow, initializing variables is always a
     good practice!  */
    
    // If the doc is brand new, have to force the autosave to write to disk
    if (!self.fileURL && !self.autosavedContentsFileURL && !self.hasUnautosavedChanges)
    {
        [self updateChangeCount:NSChangeDone];
        NSDocument *result = [self duplicateAndReturnError:outError];
        [self updateChangeCount:NSChangeUndone];
        return result;
    }
    
    
    // Make sure copy on disk is up-to-date
    if (![self fakeSynchronousAutosaveAndReturnError:outError]) return nil;
    
    
    // Let super handle the overall duplication so it gets the window-handling
    // right. But use custom writing logic that actually copies the existing doc
    BOOL (^writingBlock)(NSURL*, NSSaveOperationType, NSURL*, NSError**) = ^(NSURL *url, NSSaveOperationType saveOperation, NSURL *originalContentsURL, NSError **error) {
        return [self writeBackupToURL:url error:error];
    };
    
    self.writingBlock = writingBlock;
    NSDocument *result = [super duplicateAndReturnError:outError];
    self.writingBlock = nil;
    
    return result;
}

/*  Approximates a synchronous version of -autosaveDocumentWithDelegate:didAutosaveSelector:contextInfo:    */
- (BOOL)fakeSynchronousAutosaveAndReturnError:(NSError **)outError;
{
    NSError* __block error = nil;
    
    // Kick off an autosave
    __block BOOL result = YES;
    [self autosaveWithImplicitCancellability:NO completionHandler:^(NSError *errorOrNil) {
        if (errorOrNil)
        {
            result = NO;
            error = [errorOrNil copy];  // in case there's an autorelease pool
        }
    }];
    
    // Somewhat of a hack: wait for autosave to finish
    [self performSynchronousFileAccessUsingBlock:^{ }];
    
#if ! __has_feature(objc_arc)
    [error autorelease];   // match the -copy above
#endif
    
    if (error && outError) {
        *outError = error ;
    }

    return result;
}

- (IBAction)saveDocumentAs:(id)sender {
    self.isSaving = YES;
    [super saveDocumentAs:sender];
}


#pragma mark Error Presentation

/*! we override willPresentError: here largely to deal with
 any validation issues when saving the document
 */
- (NSError *)willPresentError:(NSError *)inError
{
    NSError *result = nil;
    
    // customizations for NSCocoaErrorDomain
    if ( [inError.domain isEqualToString:NSCocoaErrorDomain] )
    {
        NSInteger errorCode = inError.code;
        
        // is this a Core Data validation error?
        if ( (NSValidationErrorMinimum <= errorCode) && (errorCode <= NSValidationErrorMaximum) )
        {
            // If there are multiple validation errors, inError will be a NSValidationMultipleErrorsError
            // and all the validation errors will be in an array in the userInfo dictionary for key NSDetailedErrorsKey
            NSArray<NSError *> *detailedErrors = inError.userInfo[NSDetailedErrorsKey];
            if (detailedErrors)
            {
                NSUInteger numErrors = detailedErrors.count;
                NSMutableString *errorString = [NSMutableString stringWithFormat:@"%lu validation errors have occurred.", (unsigned long)numErrors];
                NSMutableString *secondary = [NSMutableString string];
                if ( numErrors > 3 )
                {
                    [secondary appendString:NSLocalizedString(@"The first 3 are:\n", @"To be followed by 3 error messages")];
                }
                
                NSUInteger i;
                for ( i = 0; i < ((numErrors > 3) ? 3 : numErrors); i++ )
                {
                    [secondary appendFormat:@"%@\n", detailedErrors[i].localizedDescription];
                }
                
                NSMutableDictionary<NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionaryWithDictionary:inError.userInfo];
                userInfo[NSLocalizedDescriptionKey] = errorString;
                userInfo[NSLocalizedRecoverySuggestionErrorKey]  = secondary;
                
                result = [NSError errorWithDomain:inError.domain code:inError.code userInfo:userInfo];
            }
        }
    }
    
    // for errors we didn't customize, call super, passing the original error
    if ( !result )
    {
        result = [super willPresentError:inError];
    }
    
    return result;
}

@end

/* Note JK20170624

 I removed code in two places which purportedly sets the document's undo
 manager as NSPersistentDocument does.  The code I removed creates a managed
 object context, which initially has nil undo manager, then later copies its
 nil undo manager to the document.  Result: document has nil undo manager.
 Furthermore, it overrides the document's -setUndoManager: to be a noop,
 making it impossible to set a non-nil undo manager later.

 I have not fully tested this in a demo project, although in one project
 (Veris) it seems to give a nil undo manager, as my analysis predicts.
 In any case, it is possibly not compatible with my requirement in another
 project (BkmkMgrs) of using Graham Cox' GCUndoManager instead of
 NSUndoManager.

 And I do not believe that the code I removed simply behaves the same as
 NSPersistentDocument, because my BkmkMgrs app had an non-nil undo manager
 before I simply replaced NSPersistentDocument with out-of-the-box
 BSManagedDocument.

 Jerry Krinock  2017-06-24
 */

/* Note JK20180125

 I've removed the above assertion because it tripped for me when I had
 enabled asynchronous saving, and I think it is a false alarm.  The call
 stack was as shown below.  Indeed it was on a secondary thread, because
 the main thread invoked
 -[BkmxDoc writeSafelyToURL:ofType:forSaveOperation:error:], which the
 system called on a secondary thread.  Is that not the whole idea of
 asynchronous saving?  For macOS 10.7+, this class does return YES for
 -canAsynchronouslyWriteToURL:::.

 Thread 50 Queue : com.apple.root.default-qos (concurrent)
 #0    0x00007fff57c3823f in -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] ()
 #1    0x00000001002b7e13 in -[BSManagedDocument contentsForURL:ofType:saveOperation:error:] at /Users/jk/Documents/Programming/Projects/BSManagedDocument/BSManagedDocument.m:396
 #2    0x00000001002b9881 in -[BSManagedDocument writeToURL:ofType:forSaveOperation:originalContentsURL:error:] at /Users/jk/Documents/Programming/Projects/BSManagedDocument/BSManagedDocument.m:872
 #3    0x00000001002b95da in -[BSManagedDocument writeSafelyToURL:ofType:forSaveOperation:error:] at /Users/jk/Documents/Programming/Projects/BSManagedDocument/BSManagedDocument.m:791
 #4    0x00000001002e0d41 in -[BkmxDoc writeSafelyToURL:ofType:forSaveOperation:error:] at /Users/jk/Documents/Programming/Projects/BkmkMgrs/BkmxDoc.m:5383
 #5    0x00007fff53c39294 in __85-[NSDocument(NSDocumentSaving) _saveToURL:ofType:forSaveOperation:completionHandler:]_block_invoke_2.1146 ()
 #6    0x0000000100887c3d in _dispatch_call_block_and_release ()
 #7    0x000000010087fd1f in _dispatch_client_callout ()
 #8    0x000000010088dba8 in _dispatch_queue_override_invoke ()
 #9    0x0000000100881b76 in _dispatch_root_queue_drain ()
 #10    0x000000010088184f in _dispatch_worker_thread3 ()
 #11    0x00000001008fc1c2 in _pthread_wqthread ()
 #12    0x00000001008fbc45 in start_wqthread ()
 Enqueued from com.apple.main-thread (Thread 1) Queue : com.apple.main-thread (serial)
 #0    0x0000000100896669 in _dispatch_root_queue_push_override ()
 #1    0x00007fff53c3916f in __85-[NSDocument(NSDocumentSaving) _saveToURL:ofType:forSaveOperation:completionHandler:]_block_invoke.1143 ()
 #2    0x00007fff535b2918 in __68-[NSDocument _errorForOverwrittenFileWithSandboxExtension:andSaver:]_block_invoke_2.1097 ()
 #3    0x00007fff57de36c1 in __110-[NSFileCoordinator(NSPrivate) _coordinateReadingItemAtURL:options:writingItemAtURL:options:error:byAccessor:]_block_invoke.448 ()
 #4    0x00007fff57de2657 in -[NSFileCoordinator(NSPrivate) _withAccessArbiter:invokeAccessor:orDont:andRelinquishAccessClaim:] ()
 #5    0x00007fff57de32cb in -[NSFileCoordinator(NSPrivate) _coordinateReadingItemAtURL:options:writingItemAtURL:options:error:byAccessor:] ()
 #6    0x00007fff53c34954 in -[NSDocument(NSDocumentSaving) _fileCoordinator:coordinateReadingContentsAndWritingItemAtURL:byAccessor:] ()
 #7    0x00007fff53c34b62 in -[NSDocument(NSDocumentSaving) _coordinateReadingContentsAndWritingItemAtURL:byAccessor:] ()
 #8    0x00007fff535b2860 in __68-[NSDocument _errorForOverwrittenFileWithSandboxExtension:andSaver:]_block_invoke.1096 ()
 #9    0x00007fff53674eb4 in -[NSDocument(NSDocumentSerializationAPIs) continueFileAccessUsingBlock:] ()
 #10    0x00007fff5367688a in __62-[NSDocument(NSDocumentSerializationAPIs) _performFileAccess:]_block_invoke.354 ()
 #11    0x00007fff535f38c0 in __62-[NSDocumentController(NSInternal) _onMainThreadInvokeWorker:]_block_invoke.2153 ()
 #12    0x00007fff55acc58c in __CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__ ()
 #13    0x00007fff55aaf043 in __CFRunLoopDoBlocks ()
 #14    0x00007fff55aae6ce in __CFRunLoopRun ()
 #15    0x00007fff55aadf43 in CFRunLoopRunSpecific ()
 #16    0x00007fff54dc5e26 in RunCurrentEventLoopInMode ()
 #17    0x00007fff54dc5b96 in ReceiveNextEventCommon ()
 #18    0x00007fff54dc5914 in _BlockUntilNextEventMatchingListInModeWithFilter ()
 #19    0x00007fff53090f5f in _DPSNextEvent ()
 #20    0x00007fff53826b4c in -[NSApplication(NSEvent) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] ()
 #21    0x00007fff53085d6d in -[NSApplication run] ()
 #22    0x00007fff53054f1a in NSApplicationMain ()
 #23    0x00000001000014bc in main at /Users/jk/Documents/Programming/Projects/BkmkMgrs/Bkmx-Main.m:83
 #24    0x00007fff7d3c1115 in start ()
*/
