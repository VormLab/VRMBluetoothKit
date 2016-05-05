//
//  VRMPeripheral.h
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
#import "VRMConfiguration.h"
#import "VRMCommandBuilder.h"
@import CoreBluetooth;

@interface VRMPeripheral : NSObject

- (instancetype)initWithConfiguration:(VRMConfiguration *)configuration;

+ (VRMPeripheral *)peripheralWithConfiguration:(VRMConfiguration *)configuration;

- (void)writeCommand:(VRMCommand *)command completionHandler:(void(^)(BOOL completed, NSError *error))handler;

- (void)writeMultipartCommand:(VRMMultipartCommand *)command progressHandler:(void(^)(CGFloat progress))progressHandler completionHandler:(void(^)(BOOL completed, NSError *error))handler;

- (void)readValueFromCharacteristic:(VRMCharacteristic *)characteristic completionHandler:(void(^)(NSData *data, NSError *error))handler;

@property (nonatomic, copy) void(^disconnectionHandler)(NSError *error);

@property (nonatomic, strong) id identifier;
@property (nonatomic, readonly, assign) BOOL connected;
@property (nonatomic, readonly, strong) VRMConfiguration *configuration;

@property (nonatomic, strong) CBPeripheral *peripheral;

@end
