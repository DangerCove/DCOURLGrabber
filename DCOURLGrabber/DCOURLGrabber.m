//
//  DCOURLGrabber.m
//  Tapetrap
//
//  Created by Boy van Amstel on 18-11-13.
//  Copyright (c) 2013 Danger Cove. All rights reserved.
//

#import "DCOURLGrabber.h"

// The DCOURLGrabber error domain.
NSString        *   const   kDCOURLGrabberErrorDomain                   = @"com.dangercove.DCOURLGrabber.ErrorDomain";

// The DCOURLGrabber error that is displayed when the bundle ID was not set
NSString        *   const   kDCOURLGrabberErrorBundleIDNotSet           = @"Failed to find application to get URL from";
// The DCOURLGrabber error that is displayed when the AppleScript was not found
NSString        *   const   kDCOURLGrabberErrorScriptNotFound           = @"Failed to find script for %@";
// The DCOURLGrabber error that is displayed when the AppleScript was not found
NSString        *   const   kDCOURLGrabberErrorBrowserNotRunning        = @"The browser with bundle ID %@ is not running";
// The DCOURLGrabber error that is displayed when the AppleScript failed to execute
NSString        *   const   kDCOURLGrabberErrorScriptExecutionFailed    = @"Failed to run script for %@:\n%@";

@interface DCOURLGrabber()

/* The bundle ID of the app that was activated last. */
@property (copy) NSString *lastActiveBundleID;

/* Registers whether the class is monitoring. */
@property (assign, getter = isMonitoring) BOOL monitoring;

/* 
 * Bundle IDs of apps that have supported AppleScripts. 
 */
+ (NSArray *)supportedBundleIDs;

/* 
 * Fires each time the user switches apps. 
 *
 * @param notification The app switch notification. 
 */
- (void)appDidActivate:(NSNotification *)notification;

/* 
 * Returns a new error with the correct error domain.
 *
 * @param code The `DCOURLErrorCode` that corresponds with the error.
 * @param message The localized description for the error.
 */
- (NSError *)errorForCode:(DCOURLGrabberErrorCode)code withDescription:(NSString *)description;

@end

@implementation DCOURLGrabber

#pragma mark - Class Methods

+ (NSArray *)supportedBundleIDs {
    static id supportedBundleIDs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedBundleIDs = [NSArray arrayWithObjects:
                              @"com.apple.Safari",
                              @"com.google.Chrome",
                              @"com.operasoftware.Opera",
                              @"org.mozilla.firefox",
                              nil];
    });
    return supportedBundleIDs;
}

+ (id)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Overrides

- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark - Utilities

- (NSError *)errorForCode:(DCOURLGrabberErrorCode)code withDescription:(NSString *)description {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          description, NSLocalizedDescriptionKey,
                          nil];
    return [[NSError alloc] initWithDomain:kDCOURLGrabberErrorDomain code:code userInfo:dict];
}

#pragma mark - Event Listeners

- (void)startMonitoring {
    if(self.isMonitoring) return;
    
    // Register for app switching
    self.monitoring = YES;
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(appDidActivate:)
                                                               name:NSWorkspaceDidActivateApplicationNotification
                                                             object:nil];
}

- (void)stopMonitoring {
    if(!self.monitoring) return;
    
    // Stop listening
    self.monitoring = NO;
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidActivateApplicationNotification object:nil];

}

- (void)appDidActivate:(NSNotification *)notification {
    NSRunningApplication *app = [notification.userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    
    if([[DCOURLGrabber supportedBundleIDs] containsObject:app.bundleIdentifier]) {
        // Set last activated app
        self.lastActiveBundleID = app.bundleIdentifier;
    }
}

#pragma mark - Actual URL Grabbing

- (NSURL *)grabURLFromBundleID:(NSString *)bundleID withError:(NSError *__autoreleasing *)error {

    // Check if applescript is available
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:self.lastActiveBundleID ofType:@"scpt"];
    NSDictionary *scriptLoadError;
    NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&scriptLoadError];
    
    if(scriptLoadError) {
        *error = [self errorForCode:DCOURLGrabberErrorCodeScriptNotFound withDescription:kDCOURLGrabberErrorScriptNotFound];
        
        return nil;
    }
    
    // Check if app with bundle ID is running
    if([NSRunningApplication runningApplicationsWithBundleIdentifier:self.lastActiveBundleID].count < 1) {
        *error = [self errorForCode:DCOURLGrabberErrorCodeBrowserNotRunning withDescription:kDCOURLGrabberErrorBrowserNotRunning];
        
        return nil;
    }
    
    // Grab URL
    // Execute the AppleScript
    NSDictionary *scriptExecuteError;
    NSAppleEventDescriptor *result = [script executeAndReturnError:&scriptExecuteError];
    if(scriptExecuteError) {
        
        *error = [self errorForCode:DCOURLGrabberErrorCodeScriptExecutionFailed withDescription:[NSString stringWithFormat:kDCOURLGrabberErrorScriptExecutionFailed, self.lastActiveBundleID, scriptExecuteError]];
        
        return nil;
    }
    
    // Check if we got something
//    if(result.stringValue && result.stringValue.length > 0) {
    return [[NSURL alloc] initWithString:result.stringValue];
//    }
}

- (NSURL *)grabURLWithError:(NSError *__autoreleasing *)error {
    if(!self.lastActiveBundleID) { // No compatible app was switched to, or the bundle hasn't been set
        *error = [self errorForCode:DCOURLGrabberErrorCodeBundleIDNotSet withDescription:kDCOURLGrabberErrorBundleIDNotSet];
        return nil;
    }
    
    return [self grabURLFromBundleID:self.lastActiveBundleID withError:error];
}

@end
