//
//  LXAutoCodingObject.m
//  ViaggiaTreno iPhone
//
//  Created by Filippo Testini on 14/06/12.
//  Copyright (c) 2012 Lynx S.p.A. All rights reserved.
//

#import "LXAutoCodingObject.h"
#import <objc/runtime.h>

@implementation LXAutoCodingObject
@synthesize dictionaryRepresentation = _dictionaryRepresentation;

#pragma mark - NSCoding
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        dirty = YES;
        
        NSArray *propsKeys = [self.dictionaryRepresentation allKeys];
        for (NSString *propKey in propsKeys)
        {
            NSString *capitalizedPropKey = [propKey stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[propKey substringToIndex:1] uppercaseString]];
            
            NSObject *decodedObject = [aDecoder decodeObjectForKey:propKey];
            SEL propertySetter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", capitalizedPropKey]);
            
            [self performSelector:propertySetter withObject:decodedObject];
            
            [self addObserver:self forKeyPath:propKey options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
        }
        
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[NSKeyedArchiver class]]) 
    {
        NSArray *propsKeys = [self.dictionaryRepresentation allKeys];
        for (NSString *propKey in propsKeys)
        {
            [aCoder encodeObject:[self.dictionaryRepresentation objectForKey:propKey] forKey:propKey];
        }
    }
    else 
    {
        [NSException raise:NSInvalidArchiveOperationException
                    format:@"Only supports NSKeyedArchiver coders"];
    }
}

#pragma mark - Getters
-(NSDictionary *)dictionaryRepresentation 
{
    if (dirty)
    {
        NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionary];
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            NSString *propType = [self getPropType:property];
            NSString *propertyName = [self getPropName:property];
            
            [propertyDictionary setObject:[self safePropertyValueForName:propertyName type:propType] forKey:propertyName];
        }
        free(properties);
        
        _dictionaryRepresentation = [NSDictionary dictionaryWithDictionary:propertyDictionary];
    }
    
    return _dictionaryRepresentation;
}

#pragma mark - KVO implementation for dirty state

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dirty = YES;
}

#pragma mark - Private Methods

-(NSString*)getPropName:(objc_property_t)property
{
    return [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
}

-(NSString*)getPropType:(objc_property_t)property
{
    return [[[[NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding] componentsSeparatedByString:@","] objectAtIndex:0] substringFromIndex:1];
}

-(id)safePropertyValueForName:(NSString*)propertyName type:(NSString*)propertyType
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:NSSelectorFromString(propertyName)]];
    [invocation setSelector:NSSelectorFromString(propertyName)];
    [invocation setTarget:self];
    [invocation invoke];
    
    unichar typeIdentifier = [propertyType characterAtIndex:0];
    
    if (typeIdentifier == '@')
    {
        //NSObject instance
        NSObject *propertyValue;
        [invocation getReturnValue:&propertyValue];
        
        if (!propertyValue)
        {
            return [NSNull null];
        }
        
        return propertyValue;
    }
    
    if (typeIdentifier == 'c')
    {
        //boolean
        BOOL propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithBool:propertyValue];
    }
    
    if (typeIdentifier == 'i')
    {
        //primitive int
        int propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithInt:propertyValue];
    }
    
    if (typeIdentifier == 'l')
    {
        //primitive long
        long propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithLong:propertyValue];
    }
    
    if (typeIdentifier == 'L')
    {
        //primitive unsigned long
        unsigned long propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithUnsignedLong:propertyValue];
    }
    
    if (typeIdentifier == 'Q')
    {
        //primitive unsigned long long
        unsigned long long propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithUnsignedLongLong:propertyValue];
    }
    
    if (typeIdentifier == 's')
    {
        //primitive short
        short propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithShort:propertyValue];
    }
    
    if (typeIdentifier == 'f')
    {
        //primitive float
        float propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithFloat:propertyValue];
    }
    
    if (typeIdentifier == 'd')
    {
        //primitive double
        double propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithDouble:propertyValue];
    }
    
    if (typeIdentifier == 'I')
    {
        //primitive unsigned
        unsigned propertyValue;
        [invocation getReturnValue:&propertyValue];
        return [NSNumber numberWithUnsignedInt:propertyValue];
    }
    
    return nil;
}

-(NSString *)description
{    
    return [self.dictionaryRepresentation description];
}

-(void)dealloc
{    
    for (NSString *propKey in [self.dictionaryRepresentation allKeys])
    {
        [self removeObserver:self forKeyPath:propKey];
    }
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end
