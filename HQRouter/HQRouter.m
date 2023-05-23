//
//  HQRouter.m
//  HQRouter
//
//  Created by QuanHe on 2023/5/23.
//

#import "HQRouter.h"
#import "HQRouterLogger.h"

static NSString *const HQRouterWildcard = @"*";
static NSString *HQSpecialCharacters = @"/?&.";

static NSString *const HQRouterCoreKey = @"HQRouterCore";
static NSString *const HQRouterCoreBlockKey = @"HQRouterCoreBlock";
static NSString *const HQRouterCoreTypeKey = @"HQRouterCoreType";

NSString *const HQRouterParameterURLKey = @"HQRouterParameterURL";

typedef NS_ENUM(NSInteger,HQRouterType) {
    HQRouterTypeDefault = 0,
    HQRouterTypeObject = 1,
    HQRouterTypeCallback = 2,
};

@interface HQRouter()

@property (nonatomic,strong) NSMutableDictionary *routes;

@property (nonatomic,strong) HQRouterUnregisterURLHandler routerUnregisterURLHandler;

@end

@implementation HQRouter

+ (instancetype)sharedInstance
{
    static HQRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Public Methods
+ (void)registerRouteURL:(NSString *)routeURL handler:(HQRouterHandler)handlerBlock {
    HQRouterLog(@"registerRouteURL:%@",routeURL);
    [[self sharedInstance] addRouteURL:routeURL handler:handlerBlock];
}

+ (void)registerObjectRouteURL:(NSString *)routeURL handler:(HQObjectRouterHandler)handlerBlock {
    HQRouterLog(@"registerObjectRouteURL:%@",routeURL);
    [[self sharedInstance] addObjectRouteURL:routeURL handler:handlerBlock];
}

+ (void)registerCallbackRouteURL:(NSString *)routeURL handler:(HQCallbackRouterHandler)handlerBlock {
    HQRouterLog(@"registerCallbackRouteURL:%@",routeURL);
    [[self sharedInstance] addCallbackRouteURL:routeURL handler:handlerBlock];
}

+ (BOOL)canRouteURL:(NSString *)URL {
    NSString *rewriteURL = [HQRouterRewrite rewriteURL:URL];
    return [[self sharedInstance] achieveParametersFromURL:rewriteURL] ? YES : NO;
}

+ (void)routeURL:(NSString *)URL {
    [self routeURL:URL withParameters:nil];
}

+ (void)routeURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    HQRouterLog(@"Route to URL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [HQRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        HQRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[HQRouterCoreKey];
        HQRouterHandler handler = coreDic[HQRouterCoreBlockKey];
        HQRouterType type = [coreDic[HQRouterCoreTypeKey] integerValue];
        if (type != HQRouterTypeDefault) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        
        if (handler) {
            if (parameters) {
                [routerParameters addEntriesFromDictionary:parameters];
            }
            [routerParameters removeObjectForKey:HQRouterCoreKey];
            handler(routerParameters);
        }
    }
}

+ (id)routeObjectURL:(NSString *)URL {
    return [self routeObjectURL:URL withParameters:nil];
}

+ (id)routeObjectURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    HQRouterLog(@"Route to ObjectURL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [HQRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        HQRouterErrorLog(@"Route unregistered ObjectURL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return nil;
    }
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    NSDictionary *coreDic = routerParameters[HQRouterCoreKey];
    HQObjectRouterHandler handler = coreDic[HQRouterCoreBlockKey];
    HQRouterType type = [coreDic[HQRouterCoreTypeKey] integerValue];
    if (type != HQRouterTypeObject) {
        [self routeTypeCheckLogWithCorrectType:type url:URL];
        return nil;
    }
    if (handler) {
        if (parameters) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        [routerParameters removeObjectForKey:HQRouterCoreKey];
        return handler(routerParameters);
    }
    return nil;
}

+ (void)routeCallbackURL:(NSString *)URL targetCallback:(HQRouterCallback)targetCallback {
    [self routeCallbackURL:URL withParameters:nil targetCallback:targetCallback];
}

+ (void)routeCallbackURL:(NSString *)URL withParameters:( NSDictionary<NSString *, id> *) parameters targetCallback:(HQRouterCallback)targetCallback {
    HQRouterLog(@"Route to URL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [HQRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        HQRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[HQRouterCoreKey];
        HQCallbackRouterHandler handler = coreDic[HQRouterCoreBlockKey];
        HQRouterType type = [coreDic[HQRouterCoreTypeKey] integerValue];
        if (type != HQRouterTypeCallback) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        if (parameters) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        
        if (handler) {
            [routerParameters removeObjectForKey:HQRouterCoreKey];
            handler(routerParameters,^(id callbackObjc){
                if (targetCallback) {
                    targetCallback(callbackObjc);
                }
            });
        }
    }
}


+ (void)routeUnregisterURLHandler:(HQRouterUnregisterURLHandler)handler {
    [[self sharedInstance] setRouterUnregisterURLHandler:handler];
}

+ (void)unregisterRouteURL:(NSString *)URL {
    [[self sharedInstance] removeRouteURL:URL];
    HQRouterLog(@"Unregister URL:%@\nroutes:%@",URL,[[self sharedInstance] routes]);
}

+ (void)unregisterAllRoutes {
    [[self sharedInstance] removeAllRouteURL];
    HQRouterLog(@"Unregister All URL\nroutes:%@",[[self sharedInstance] routes]);
}

+ (void)setLogEnabled:(BOOL)enable {
    [HQRouterLogger enableLog:enable];
}

#pragma mark - Private Methods
- (void)addRouteURL:(NSString *)routeUrl handler:(HQRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{HQRouterCoreBlockKey:[handlerBlock copy],HQRouterCoreTypeKey:@(HQRouterTypeDefault)};
        subRoutes[HQRouterCoreKey] = coreDic;
    }
}

- (void)addObjectRouteURL:(NSString *)routeUrl handler:(HQObjectRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{HQRouterCoreBlockKey:[handlerBlock copy],HQRouterCoreTypeKey:@(HQRouterTypeObject)};
        subRoutes[HQRouterCoreKey] = coreDic;
    }
}

- (void)addCallbackRouteURL:(NSString *)routeUrl handler:(HQCallbackRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{HQRouterCoreBlockKey:[handlerBlock copy],HQRouterCoreTypeKey:@(HQRouterTypeCallback)};
        subRoutes[HQRouterCoreKey] = coreDic;
    }
}

- (NSMutableDictionary *)addURLPattern:(NSString *)URLPattern {
    NSArray *pathComponents = [self pathComponentsFromURL:URLPattern];
    
    NSMutableDictionary* subRoutes = self.routes;
    
    for (NSString* pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    return subRoutes;
}

- (void)unregisterURLBeRouterWithURL:(NSString *)URL {
    if (self.routerUnregisterURLHandler) {
        self.routerUnregisterURLHandler(URL);
    }
}

- (void)removeRouteURL:(NSString *)routeUrl{
    if (self.routes.count <= 0) {
        return;
    }
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromURL:routeUrl]];
    BOOL firstPoll = YES;
    
    while(pathComponents.count > 0){
        NSString *componentKey = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *route = [self.routes valueForKeyPath:componentKey];
        
        if (route.count > 1 && firstPoll) {
            [route removeObjectForKey:HQRouterCoreKey];
            break;
        }
        if (route.count <= 1 && firstPoll){
            NSString *lastComponent = [pathComponents lastObject];
            [pathComponents removeLastObject];
            NSString *parentComponent = [pathComponents componentsJoinedByString:@"."];
            route = [self.routes valueForKeyPath:parentComponent];
            [route removeObjectForKey:lastComponent];
            firstPoll = NO;
            continue;
        }
        if (route.count > 0 && !firstPoll){
            break;
        }
    }
}

- (void)removeAllRouteURL {
    [self.routes removeAllObjects];
}

- (NSArray*)pathComponentsFromURL:(NSString*)URL {
    
    NSMutableArray *pathComponents = [NSMutableArray array];
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        [pathComponents addObject:pathSegments[0]];
        for (NSInteger idx = 1; idx < pathSegments.count; idx ++) {
            if (idx == 1) {
                URL = [pathSegments objectAtIndex:idx];
            }else{
                URL = [NSString stringWithFormat:@"%@://%@",URL,[pathSegments objectAtIndex:idx]];
            }
        }
    }
    
    if ([URL hasPrefix:@":"]) {
        if ([URL rangeOfString:@"/"].location != NSNotFound) {
            NSArray *pathSegments = [URL componentsSeparatedByString:@"/"];
            [pathComponents addObject:pathSegments[0]];
        }else{
            [pathComponents addObject:URL];
        }
    }else{
        for (NSString *pathComponent in [[NSURL URLWithString:URL] pathComponents]) {
            if ([pathComponent isEqualToString:@"/"]) continue;
            if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
            [pathComponents addObject:pathComponent];
        }
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)achieveParametersFromURL:(NSString *)url{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[HQRouterParameterURLKey] = [url stringByRemovingPercentEncoding];
    
    NSMutableDictionary* subRoutes = self.routes;
    NSArray* pathComponents = [self pathComponentsFromURL:url];
    
    NSInteger pathComponentsSurplus = [pathComponents count];
    BOOL wildcardMatched = NO;
    
    for (NSString* pathComponent in pathComponents) {
        NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch;
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj2 compare:obj1 options:comparisonOptions];
        }];
        
        for (NSString* key in subRoutesKeys) {
            
            if([pathComponent isEqualToString:key]){
                pathComponentsSurplus --;
                subRoutes = subRoutes[key];
                break;
            }else if([key hasPrefix:@":"] && pathComponentsSurplus == 1){
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                
                NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:HQSpecialCharacters];
                NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                
                if (range.location != NSNotFound) {
                    newKey = [newKey substringToIndex:range.location - 1];
                    NSString *suHQixToStrip = [key substringFromIndex:range.location];
                    newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suHQixToStrip withString:@""];
                }
                parameters[newKey] = newPathComponent;
                break;
            }else if([key isEqualToString:HQRouterWildcard] && !wildcardMatched){
                subRoutes = subRoutes[key];
                wildcardMatched = YES;
                break;
            }
        }
    }
    
    if (!subRoutes[HQRouterCoreKey]) {
        return nil;
    }
    
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    parameters[HQRouterCoreKey] = [subRoutes[HQRouterCoreKey] copy];
    return parameters;
}

+ (void)routeTypeCheckLogWithCorrectType:(HQRouterType)correctType url:(NSString *)URL{
    if (correctType == HQRouterTypeDefault) {
        HQRouterErrorLog(@"You must use [routeURL:] or [routeURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == HQRouterTypeObject) {
        HQRouterErrorLog(@"You must use [routeObjectURL:] or [routeObjectURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == HQRouterTypeCallback) {
        HQRouterErrorLog(@"You must use [routeCallbackURL: targetCallback:] or [routeCallbackURL: withParameters: targetCallback:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }
}


#pragma mark - getter/setter
- (NSMutableDictionary *)routes {
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    return _routes;
}

@end
