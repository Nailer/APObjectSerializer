#import "APObjectSerializerSpec.h"


@implementation APObjectSerializerSpec

- (instancetype)initWithTargetClass:(Class)targetClass nameMappings:(NSDictionary *)nameMappings typeMappings:(NSDictionary *)typeMappings
{
    self = [super init];
    if (self)
    {
        _targetClass = [targetClass copy];
        _nameMappings = [nameMappings copy];
        _reverseNameMappings = [self buildReverseNameMappings:_nameMappings];
        _typeMappings = [typeMappings copy];
    }

    return self;
}

- (NSDictionary *)buildReverseNameMappings:(NSDictionary *)nameMappings
{
    NSMutableDictionary *reverseMappings = [NSMutableDictionary new];
    [nameMappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop)
    {
        reverseMappings[obj] = key;
    }];

    return reverseMappings;
}

@end
