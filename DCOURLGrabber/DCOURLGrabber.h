//
//  DCOURLGrabber.h
//  Tapetrap
//
//  Created by Boy van Amstel on 18-11-13.
//  Copyright (c) 2013 Danger Cove. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DCOURLGrabberErrorCode) {
    DCOURLGrabberErrorCodeNoError               = 0,
    DCOURLGrabberErrorCodeBundleIDNotSet        = 100,
    DCOURLGrabberErrorCodeScriptNotFound        = 200,
    DCOURLGrabberErrorCodeBrowserNotRunning     = 300,
    DCOURLGrabberErrorCodeScriptExecutionFailed = 400,
};

/**
 *  Grabs the current URL of a specific web browser, or the last one active.
 */
@interface DCOURLGrabber : NSObject

/**
 *  Start listening for app switches.
 */
- (void)startMonitoring;

/**
 *  Stop listening for app switches.
 */
- (void)stopMonitoring;

/**
 *  Grab the URL from an app with the specified bundle ID.
 *
 *  @param bundleID The bundle ID to grab the URL from.
 *  @param error Will contain the error when grabbing fails.
 *
 *  @return Returns the `NSURL`.
 */
- (NSURL *)grabURLFromBundleID:(NSString *)bundleID withError:(NSError **)error;

/**
 *  Grab the the URL of the browser that was last active.
 *
 *  @param error Will contain the error when grabbing fails.
 *
 *  @return Returns the `NSURL`.
 */
- (NSURL *)grabURLWithError:(NSError **)error;

@end
