//
//  HQRouterRewrite.m
//  HQRouter
//
//  Created by QuanHe on 2023/5/23.
//

#import "HQRouterRewrite.h"
#import "HQRouterLogger.h"

NSString *const HQRouterRewriteMatchRuleKey = @"matchRule";
NSString *const HQRouterRewriteTargetRuleKey = @"targetRule";

NSString *const HQRouterRewriteComponentURLKey = @"url";
NSString *const HQRouterRewriteComponentSchemeKey = @"scheme";
NSString *const HQRouterRewriteComponentHostKey = @"host";
NSString *const HQRouterRewriteComponentPortKey = @"port";
NSString *const HQRouterRewriteComponentPathKey = @"path";
NSString *const HQRouterRewriteComponentQueryKey = @"query";
NSString *const HQRouterRewriteComponentFragmentKey = @"fragment";

@interface HQRouterRewrite()

@property(nonatomic, strong) NSMutableArray *rewriteRules;

@end

@implementation HQRouterRewrite

+ (instancetype)sharedInstance
{
    static HQRouterRewrite *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Public Methods
+ (NSString *)rewriteURL:(NSString *)URL {
    
    if (!URL) return nil;
    if ([[self sharedInstance] rewriteRules].count == 0 ) return URL;
    
    NSString *rewriteCaptureGroupsURL = [self rewriteCaptureGroupsWithOriginalURL:URL];
    NSString *rewrittenURL = [self rewriteComponentsWithOriginalURL:URL targetRule:rewriteCaptureGroupsURL];
    if (![rewrittenURL isEqualToString:URL]) {
        HQRouterLog(@"rewriteURL:%@ to:%@",URL,rewrittenURL);
    }
    return rewrittenURL;
}

+ (void)addRewriteMatchRule:(NSString *)matchRule targetRule:(NSString *)targetRule {
    HQRouterLog(@"addRewriteMatchRule matchRule:%@ targetRule:%@",matchRule,targetRule);
    
    if (!matchRule || !targetRule) return;
    
    NSArray *rules = [[[self sharedInstance] rewriteRules] copy];
    
    for (int idx = 0; idx < rules.count; idx ++) {
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        if ([[ruleDic objectForKey:HQRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[[self sharedInstance] rewriteRules] removeObject:ruleDic];
        }
    }

    NSDictionary *ruleDic = @{HQRouterRewriteMatchRuleKey:matchRule,HQRouterRewriteTargetRuleKey:targetRule};
    [[[self sharedInstance] rewriteRules] addObject:ruleDic];

}

+ (void)addRewriteRules:(NSArray<NSDictionary *> *)rules {
    if (!rules) return;
    HQRouterLog(@"addRewriteRules:%@",rules);
    
    for (int idx = 0; idx < rules.count; idx ++) {
        id ruleObjc = [rules objectAtIndex:idx];
        
        if (![ruleObjc isKindOfClass:[NSDictionary class]]) {
            HQRouterErrorLog(@"The data type is not valid,the element must be a dictionary. invalid data:%@",ruleObjc);
            continue;
        }
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        NSString *matchRule = [ruleDic objectForKey:HQRouterRewriteMatchRuleKey];
        NSString *targetRule = [ruleDic objectForKey:HQRouterRewriteTargetRuleKey];
        if (!matchRule || !targetRule) {
            HQRouterErrorLog(@"The data type is not valid,The dictionary must contain two keys:\"%@\" and \"%@\".invalid data:%@",HQRouterRewriteMatchRuleKey,HQRouterRewriteTargetRuleKey,ruleDic);
            continue;
        }
        [self addRewriteMatchRule:matchRule targetRule:targetRule];
        
    }
}

+ (void)removeRewriteMatchRule:(NSString *)matchRule {
    HQRouterLog(@"removeRewriteMatchRule:%@",matchRule);
    NSArray *rules = [[[self sharedInstance] rewriteRules] copy];
    
    for (int idx = 0; idx < rules.count; idx ++) {
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        if ([[ruleDic objectForKey:HQRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[[self sharedInstance] rewriteRules] removeObject:ruleDic];
            break;
        }
    }
}

+ (void)removeAllRewriteRules {
    [[[self sharedInstance] rewriteRules] removeAllObjects];
    HQRouterLog(@"removeAllRewriteRules,rewriteRules:%@",[[self sharedInstance] rewriteRules]);
}

#pragma mark - Private Methods
+ (NSString *)rewriteCaptureGroupsWithOriginalURL:(NSString *)originalURL {
    
    NSArray *rules = [[self sharedInstance] rewriteRules];
    
    if ([rules isKindOfClass:[NSArray class]] && rules.count > 0) {
        NSString *targetURL = originalURL;
        NSRegularExpression *replaceRx = [NSRegularExpression regularExpressionWithPattern:@"[$]([$|#]?)(\\d+)" options:0 error:NULL];
        
        for (NSDictionary *rule in rules) {
            NSString *matchRule = [rule objectForKey:HQRouterRewriteMatchRuleKey];
            if (!([matchRule isKindOfClass:[NSString class]] && matchRule.length > 0)) continue;
            
            NSRange searchRange = NSMakeRange(0, targetURL.length);
            NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:matchRule options:0 error:NULL];
            NSRange range = [rx rangeOfFirstMatchInString:targetURL options:0 range:searchRange];
            
            if (range.length != 0) {
                NSMutableArray *groupValues = [NSMutableArray array];
                NSTextCheckingResult *result = [rx firstMatchInString:targetURL options:0 range:searchRange];
                for (NSInteger idx = 0; idx<rx.numberOfCaptureGroups + 1; idx++) {
                    NSRange groupRange = [result rangeAtIndex:idx];
                    if (groupRange.length != 0) {
                        [groupValues addObject:[targetURL substringWithRange:groupRange]];
                    }
                }
                NSString *targetRule = [rule objectForKey:HQRouterRewriteTargetRuleKey];
                NSMutableString *newTargetURL = [NSMutableString stringWithString:targetRule];
                [replaceRx enumerateMatchesInString:targetRule options:0 range:NSMakeRange(0, targetRule.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                    NSRange matchRange = result.range;

                    NSRange secondGroupRange = [result rangeAtIndex:2];
                    NSString *replacedValue = [targetRule substringWithRange:matchRange];
                    NSInteger index = [[targetRule substringWithRange:secondGroupRange] integerValue];
                    if (index >= 0 && index < groupValues.count) {
                        
                        NSString *newValue = [self convertCaptureGroupsWithCheckingResult:result targetRule:targetRule originalValue:groupValues[index]];
                        [newTargetURL replaceOccurrencesOfString:replacedValue withString:newValue options:0 range:NSMakeRange(0, newTargetURL.length)];
                    }
                }];
                return newTargetURL;
            }
        }
    }
    return originalURL;
}

+ (NSString *)rewriteComponentsWithOriginalURL:(NSString *)originalURL targetRule:(NSString *)targetRule {
    
    NSString *encodeURL = [originalURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:encodeURL];
    NSMutableDictionary *componentDic = [[NSMutableDictionary alloc] init];
    [componentDic setValue:originalURL forKey:HQRouterRewriteComponentURLKey];
    [componentDic setValue:urlComponents.scheme forKey:HQRouterRewriteComponentSchemeKey];
    [componentDic setValue:urlComponents.host forKey:HQRouterRewriteComponentHostKey];
    [componentDic setValue:urlComponents.port forKey:HQRouterRewriteComponentPortKey];
    [componentDic setValue:urlComponents.path forKey:HQRouterRewriteComponentPathKey];
    [componentDic setValue:urlComponents.query forKey:HQRouterRewriteComponentQueryKey];
    [componentDic setValue:urlComponents.fragment forKey:HQRouterRewriteComponentFragmentKey];
    
    NSMutableString *targetURL = [NSMutableString stringWithString:targetRule];
    NSRegularExpression *replaceRx = [NSRegularExpression regularExpressionWithPattern:@"[$]([$|#]?)(\\w+)" options:0 error:NULL];
    
    [replaceRx enumerateMatchesInString:targetRule options:0 range:NSMakeRange(0, targetRule.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSRange matchRange = result.range;
        NSRange secondGroupRange = [result rangeAtIndex:2];
        NSString *replaceValue = [targetRule substringWithRange:matchRange];
        NSString *componentKey = [targetRule substringWithRange:secondGroupRange];
        NSString *componentValue = [componentDic valueForKey:componentKey];
        if (!componentValue) {
            componentValue = @"";
        }
        
        NSString *newValue = [self convertCaptureGroupsWithCheckingResult:result targetRule:targetRule originalValue:componentValue];
        [targetURL replaceOccurrencesOfString:replaceValue withString:newValue options:0 range:NSMakeRange(0, targetURL.length)];
    }];
    
    return targetURL;
}


+ (NSString *)convertCaptureGroupsWithCheckingResult:(NSTextCheckingResult *)checkingResult targetRule:(NSString *)targetRule originalValue:(NSString *)originalValue {
    
    NSString *convertValue = originalValue;

    NSRange convertKeyRange = [checkingResult rangeAtIndex:1];
    NSString *convertKey = [targetRule substringWithRange:convertKeyRange];
    if ([convertKey isEqualToString:@"$"]) {
        //URL Encode
        convertValue = [originalValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }else if([convertKey isEqualToString:@"#"]){
        //URL Decode
        convertValue = [originalValue stringByRemovingPercentEncoding];
    }
    
    return convertValue;
}


#pragma mark - getter/setter
- (NSMutableArray *)rewriteRules {
    if (!_rewriteRules) {
        _rewriteRules = [[NSMutableArray alloc] init];
    }
    return _rewriteRules;
}



@end
