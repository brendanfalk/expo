// Copyright 2015-present 650 Industries. All rights reserved.

#import <AVKit/AVKit.h>

#import <ABI46_0_0EXAV/ABI46_0_0EXVideoPlayerViewControllerDelegate.h>

@interface ABI46_0_0EXVideoPlayerViewController : AVPlayerViewController

@property (nonatomic, weak) id<ABI46_0_0EXVideoPlayerViewControllerDelegate> rctDelegate;

@end
