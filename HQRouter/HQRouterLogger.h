//
//  HQRouterLogger.h
//  HQRouter
//
//  Created by QuanHe on 2023/5/23.
//

#import <Foundation/Foundation.h>


#define HQRouterLogLevel(lvl,fmt,...)\
[HQRouterLogger log : YES                                      \
level : lvl                                                  \
format : (fmt), ## __VA_ARGS__]

#define HQRouterLog(fmt,...)\
HQRouterLogLevel(HQRouterLoggerLevelInfo,(fmt), ## __VA_ARGS__)

#define HQRouterWarningLog(fmt,...)\
HQRouterLogLevel(HQRouterLoggerLevelWarning,(fmt), ## __VA_ARGS__)

#define HQRouterErrorLog(fmt,...)\
HQRouterLogLevel(HQRouterLoggerLevelError,(fmt), ## __VA_ARGS__)


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,HQRouterLoggerLevel){
    HQRouterLoggerLevelInfo = 1,
    HQRouterLoggerLevelWarning ,
    HQRouterLoggerLevelError ,
};

@interface HQRouterLogger : NSObject

@property(class , readonly, strong) HQRouterLogger *sharedInstance;

+ (BOOL)isLoggerEnabled;

+ (void)enableLog:(BOOL)enableLog;

+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
     format:(NSString *)format, ...;

@end
NS_ASSUME_NONNULL_END
