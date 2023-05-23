//
//  HQRouter.h
//  HQRouter
//
//  Created by QuanHe on 2023/5/23.
//

#import <Foundation/Foundation.h>
#import "HQRouterRewrite.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const HQRouterParameterURLKey;

typedef void (^HQRouterHandler)(NSDictionary *routerParameters);
typedef id _Nullable (^HQObjectRouterHandler)(NSDictionary *routerParameters);

typedef void (^HQRouterCallback)(id callbackObjc);
typedef void (^HQCallbackRouterHandler)(NSDictionary *routerParameters,HQRouterCallback targetCallback);

typedef void (^HQRouterUnregisterURLHandler)(NSString *routerURL);

@interface HQRouter : NSObject


/**
 Register URL,use it with 'routeURL:' and 'routeURL: withParameters:'.
 
 @param routeURL Registered URL
 @param handlerBlock Callback after route
 */
+ (void)registerRouteURL:(NSString *)routeURL handler:(HQRouterHandler)handlerBlock;

/**
 Register URL,use it with 'routeObjectURL:' and ‘routeObjectURL: withParameters:’,can return a Object.
 
 @param routeURL Registered URL
 @param handlerBlock Callback after route, and you can get a Object in this callback.
 */
+ (void)registerObjectRouteURL:(NSString *)routeURL handler:(HQObjectRouterHandler)handlerBlock;

/**
 Registered URL, use it with `routeCallbackURL: targetCallback:'and `routeCallback URL: withParameters: targetCallback:', calls back `targetCallback' asynchronously to return an Object
 
 @param routeURL Registered URL
 @param handlerBlock Callback after route,There is a `targetCallback' in `handlerBlock', which corresponds to the `targetCallback:' in `routeCallbackURL: targetCallback:'and `routeCallbackURL: withParameters: targetCallback:', which can be used for asynchronous callback to return an Object.
 */
+ (void)registerCallbackRouteURL:(NSString *)routeURL handler:(HQCallbackRouterHandler)handlerBlock;




/**
 Determine whether URL can be Route (whether it has been registered).
 
 @param URL URL to be verified
 @return Can it be routed
 */
+ (BOOL)canRouteURL:(NSString *)URL;




/**
 Route a URL
 
 @param URL URL to be routed
 */
+ (void)routeURL:(NSString *)URL;

/**
 Route a URL and bring additional parameters.
 
 @param URL URL to be routed
 @param parameters Additional parameters
 */
+ (void)routeURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters;

/**
 Route a URL and get the returned Object
 
 @param URL URL to be routed
 @return Returned Object
 */
+ (id)routeObjectURL:(NSString *)URL;

/**
 Route a URL and bring additional parameters. get the returned Object
 
 @param URL URL to be routed
 @param parameters Additional parameters
 @return Returned Object
 */
+ (id)routeObjectURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters;

/**
 Route a URL, 'targetCallBack' can asynchronously callback to return a Object.
 
 @param URL URL to be routed
 @param targetCallback asynchronous callback
 */
+ (void)routeCallbackURL:(NSString *)URL targetCallback:(HQRouterCallback)targetCallback;

/**
 Route a URL with additional parameters, and 'targetCallBack' can asynchronously callback to return a Object.
 
 @param URL URL to be routed
 @param parameters Additional parameters
 @param targetCallback asynchronous callback
 */
+ (void)routeCallbackURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters targetCallback:(HQRouterCallback)targetCallback;




/**
 Route callback for an unregistered URL
 
 @param handler Callback
 */
+ (void)routeUnregisterURLHandler:(HQRouterUnregisterURLHandler)handler;




/**
 Cancel registration of a URL
 
 @param URL URL to be cancelled
 */
+ (void)unregisterRouteURL:(NSString *)URL;

/**
 Unregister all URL
 */
+ (void)unregisterAllRoutes;



/**
 Whether to display Log for debugging
 
 @param enable YES or NO.The default is NO
 */
+ (void)setLogEnabled:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
