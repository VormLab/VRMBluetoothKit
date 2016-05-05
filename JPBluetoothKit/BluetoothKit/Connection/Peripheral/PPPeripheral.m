//
//  PPPeripheral.m
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

#import "PPPeripheral.h"
#import "PPErrorBuilder.h"

@interface PPPeripheral () <CBPeripheralDelegate>

@property (nonatomic, copy) void(^writeResponseHandler)(BOOL completed, NSError *error);
@property (nonatomic, copy) void(^multipartWriteCompletionHandler)(BOOL completed, NSError *error);
@property (nonatomic, copy) void(^readResponseHandler)(NSData *data, NSError *error);
@property (nonatomic, copy) void(^multipartProgressHandler)(CGFloat progress);

// internal blocks

@property (nonatomic, copy) void(^multipartResponseHandler)(void);

@end

@implementation PPPeripheral

- (instancetype)initWithConfiguration:(PPConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
    }
    return self;
}

+ (PPPeripheral *)peripheralWithConfiguration:(PPConfiguration *)configuration {
    
    PPPeripheral *peripheral = [[PPPeripheral alloc] initWithConfiguration:configuration];
    return peripheral;
}

- (BOOL)connected {
    if (self.peripheral && self.peripheral.state == CBPeripheralStateConnected) {
        return YES;
    }
    return NO;
}

- (void)setPeripheral:(CBPeripheral *)peripheral {
    _peripheral = peripheral;
    _peripheral.delegate = self;
}

- (void)setDisconnectionHandler:(void (^)(NSError *))disconnectionHandler {
    _disconnectionHandler = disconnectionHandler;
    [self.peripheral addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)readValueFromCharacteristic:(PPCharacteristic *)characteristic completionHandler:(void (^)(NSData *, NSError *))handler {
    if (![self connected]) {
        if (handler) {
            handler(nil, [PPErrorBuilder noDeviceConnectedError]);
        }
        return;
    }
    NSLog(@"Reading from: %@", characteristic.characteristic);
    if (characteristic.characteristic == nil) {
        NSLog(@"Trying to read from nil characteristic");
        return;
    }
    self.readResponseHandler = handler;
    [self.peripheral readValueForCharacteristic:characteristic.characteristic];
}

- (void)writeCommand:(PPCommand *)command completionHandler:(void (^)(BOOL ,NSError *))handler {
    NSLog(@"Writing command to peripheral: %@", self.peripheral);
    if (![self connected]) {
        if (handler) {
            handler(NO, [PPErrorBuilder noDeviceConnectedError]);
        }
        return;
    }
    if (command.characteristic.characteristic == nil) {
        NSLog(@"Trying to write to nil characteristic");
        return;
    }
    self.writeResponseHandler = handler;
    [self.peripheral writeValue:command.commandBody forCharacteristic:command.characteristic.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)writeMultipartCommand:(PPMultipartCommand *)command progressHandler:(void (^)(CGFloat))progressHandler completionHandler:(void (^)(BOOL, NSError *))handler {
    if (![self connected]) {
        if (handler) {
            handler(NO, [PPErrorBuilder noDeviceConnectedError]);
        }
        return;
    }
    self.multipartProgressHandler = progressHandler;
    self.multipartWriteCompletionHandler = handler;
    [self startMultipartCommand:command];
}

#pragma mark - big values transfer handling

- (void)startMultipartCommand:(PPMultipartCommand *)command {
    __weak typeof(self) weakSelf = self;
    NSData *firstChunk = [command chunkAtIndex:0];
    [self.peripheral writeValue:firstChunk forCharacteristic:command.characteristic.characteristic type:command.writeType];
    
    __block NSUInteger chunkCount = 1;
    [self setMultipartResponseHandler:^{
        if (weakSelf.multipartProgressHandler) {
            weakSelf.multipartProgressHandler([weakSelf progressForChunk:chunkCount totalChunks:command.numberOfChunks]);
        }
        if (chunkCount >= command.numberOfChunks - 1) {
            if (weakSelf.multipartWriteCompletionHandler) {
                weakSelf.multipartWriteCompletionHandler(YES, nil);
            }
            return;
        }
        NSData *nextChunk = [command chunkAtIndex:chunkCount];
        [weakSelf.peripheral writeValue:nextChunk forCharacteristic:command.characteristic.characteristic type:command.writeType];
        chunkCount ++;
    }];
}

- (CGFloat)progressForChunk:(NSUInteger)chunk totalChunks:(NSUInteger)chunks {
    return (float)chunk / (float)chunks;
}

#pragma mark - characteristics validation - unused

//- (BOOL)validateForWrite:(CBCharacteristic *)characteristic {
//    if (characteristic.properties == CBCharacteristicPropertyWrite ||
//        characteristic.properties == CBCharacteristicPropertyWriteWithoutResponse) {
//        return YES;
//    }
//    return NO;
//}
//
//- (BOOL)validateForRead:(CBCharacteristic *)characteristic {
//    if (characteristic.properties == CBCharacteristicPropertyRead) {
//        return YES;
//    }
//    return NO;
//}

#pragma mark - peripheral delegate

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Received write callback with error: %@", error);
    if (self.writeResponseHandler) {
        if (error == nil) {
            self.writeResponseHandler(YES, error);
        }
        else {
            self.writeResponseHandler(NO, error);
        }
    }
    if (self.multipartResponseHandler) {
        if (error == nil) {
            self.multipartResponseHandler();
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Received read callback with error: %@", error);
    if (self.readResponseHandler) {
        self.readResponseHandler(characteristic.value, error);
    }
    if (self.multipartResponseHandler) {
        self.multipartResponseHandler();
    }
    [self handleObservingValueChangeFor:characteristic withValue:characteristic.value];
}

- (void)handleObservingValueChangeFor:(CBCharacteristic *)characteristic withValue:(NSData *)value {
    if ([self.configuration configurationContainsCharacteristic:characteristic]) {
        PPCharacteristic *ch = [self.configuration mirrorCharacteristicFor:characteristic];
        if (ch.shouldObserveValue) {
            if (ch.valueChangeHandler) {
                ch.valueChangeHandler(value);
            }
        }
    }
}

#pragma mark - disconnection observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
        if (self.peripheral.state != CBPeripheralStateConnected) {
            if (self.disconnectionHandler) {
                self.disconnectionHandler([PPErrorBuilder disconnectionError]);
            }
            [self.peripheral removeObserver:self forKeyPath:@"state"];
            self.peripheral = nil;
        }
    }
}

#pragma mark - dealloc

- (void)dealloc {
    [self.peripheral removeObserver:self forKeyPath:@"state"];
}

@end
