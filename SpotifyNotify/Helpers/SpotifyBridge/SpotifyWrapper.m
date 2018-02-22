//
//  Spot.m
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

#import "SpotifyWrapper.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation SpotifyWrapper

+ (SpotifyApplication *) application {
	return [[SBApplication alloc] initWithBundleIdentifier: @"com.spotify.client"];
}

@end
