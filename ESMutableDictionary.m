//
//  ESMutableDictionary.m
//
//  Created by Doug Russell
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
#import "ESMutableDictionary.h"
#import "ARCLogic.h"

#if !__has_feature(objc_arc)
#error This class will leak without ARC
#endif

@implementation ESMutableDictionary
{
	NSMutableDictionary *_internalDictionary;
	dispatch_queue_t _syncQueue;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_internalDictionary = [NSMutableDictionary new];
		_syncQueue = dispatch_queue_create("com.es.mutabledictionary", DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

- (void)dealloc
{
	es_dispatch_release(_syncQueue);
}

- (void)setObject:(id)obj forKey:(id<NSCopying>)key
{
	if (!obj || !key)
		return;
	dispatch_barrier_sync(_syncQueue, ^{
		[_internalDictionary setObject:obj forKey:key];
	});
}

- (void)removeObjectForKey:(id<NSCopying>)key
{
	if (!key)
		return;
	dispatch_barrier_sync(_syncQueue, ^{
		[_internalDictionary removeObjectForKey:key];
	});
}

- (id)objectForKey:(id<NSCopying>)key
{
	if (!key)
		return nil;
	__block id value = nil;
	dispatch_sync(_syncQueue, ^(void) {
		value = [_internalDictionary objectForKey:key];
	});
	return value;
}

- (NSDictionary *)copyDictionary
{
	__block NSDictionary *dictionary;
	dispatch_sync(_syncQueue, ^(void) {
		dictionary = [_internalDictionary copy];
	});
	return dictionary;
}

- (NSUInteger)count
{
	__block NSUInteger count;
	dispatch_sync(_syncQueue, ^(void) {
		count = [_internalDictionary count];
	});
	return count;
}

@end
