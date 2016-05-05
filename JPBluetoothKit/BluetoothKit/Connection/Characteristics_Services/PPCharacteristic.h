//
//  PPCharacteristic.h
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

#import <Foundation/Foundation.h>
#import "PPService.h"
@import CoreBluetooth;

@interface PPCharacteristic : NSObject


// this initializer should be used for connection
- (instancetype)initWithContainedService:(PPService *)service uuid:(CBUUID *)uuid shouldObserveValue:(BOOL)shouldObserve;

// this initializer should be used for advertisement
- (instancetype)initWithContainedService:(PPService *)service uuid:(CBUUID *)uuid properties:(CBCharacteristicProperties)properties permissions:(CBAttributePermissions)permissions;

@property (nonatomic, readonly, strong) PPService *containedService;
@property (nonatomic, readonly, strong) CBUUID *uuid;

// used for connection
@property (nonatomic, readonly) BOOL shouldObserveValue;
@property (nonatomic, readonly) BOOL discovered;

// used for advertisement

@property (nonatomic, readonly) CBCharacteristicProperties properties;
@property (nonatomic, readonly) CBAttributePermissions permissions;

//

@property (nonatomic, strong) CBCharacteristic *characteristic;

// properties to identify given characteristic
@property (nonatomic) NSInteger identifier;
@property (nonatomic, strong) NSString *openDescription;

// called everytime when shouldObserveValue == YES and value under characteristic changes
@property (nonatomic, copy) void(^valueChangeHandler)(NSData *data);

@end
