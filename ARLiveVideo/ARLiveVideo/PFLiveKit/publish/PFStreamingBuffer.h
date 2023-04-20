//
//  PFStreamingBuffer.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "PFAudioFrame.h"
#import "PFVideoFrame.h"

/** current buffer status */
typedef NS_ENUM (NSUInteger, PFLiveBuffferState) {
    PFLiveBuffferUnknown = 0,      //< 未知
    PFLiveBuffferIncrease = 1,    //< 缓冲区状态差应该降低码率
    PFLiveBuffferDecline = 2      //< 缓冲区状态好应该提升码率
};

@class PFStreamingBuffer;
/** this two method will control videoBitRate */
@protocol PFStreamingBufferDelegate <NSObject>
@optional
/** 当前buffer变动（增加or减少） 根据buffer中的updateInterval时间回调*/
- (void)streamingBuffer:(nullable PFStreamingBuffer *)buffer bufferState:(PFLiveBuffferState)state;
@end

@interface PFStreamingBuffer : NSObject

/** The delegate of the buffer. buffer callback */
@property (nullable, nonatomic, weak) id <PFStreamingBufferDelegate> delegate;

/** current frame buffer */
@property (nonatomic, strong, readonly) NSMutableArray <PFFrame *> *_Nonnull list;

/** buffer count max size default 1000 */
@property (nonatomic, assign) NSUInteger maxCount;

/** count of drop frames in last time */
@property (nonatomic, assign) NSInteger lastDropFrames;

/** add frame to buffer */
- (void)appendObject:(nullable PFFrame *)frame;

/** pop the first frome buffer */
- (nullable PFFrame *)popFirstObject;

/** remove all objects from Buffer */
- (void)removeAllObject;

@end


