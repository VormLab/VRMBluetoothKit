//
//  PPCharacteristic.m
//
// Copyright (c) 2016 Jan Posz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PPCharacteristic.h"
#import "PPUtility.h"

@implementation PPCharacteristic

- (instancetype)initWithContainedService:(PPService *)service uuid:(CBUUID *)uuid properties:(CBCharacteristicProperties)properties permissions:(CBAttributePermissions)permissions {
    if (self = [self initWithContainedService:service uuid:uuid shouldObserveValue:NO]) {
        _properties = properties;
        _permissions = permissions;
    }
    return self;
}

- (instancetype)initWithContainedService:(PPService *)service uuid:(CBUUID *)uuid shouldObserveValue:(BOOL)shouldObserve {
    if (self = [super init]) {
        _containedService = service;
        _uuid = [PPUtility normalizedUUID:uuid error:nil];
        _shouldObserveValue = shouldObserve;
    }
    return self;
}

- (BOOL)discovered {
    if (self.characteristic) {
        return YES;
    }
    return NO;
}

- (void)setCharacteristic:(CBCharacteristic *)characteristic {
    _characteristic = characteristic;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.uuid];
}

@end
