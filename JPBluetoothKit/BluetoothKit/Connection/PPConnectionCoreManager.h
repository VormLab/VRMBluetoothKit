//
//  PPCoreStack.h
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
#import "PPPeripheral.h"
#import "PPUtility.h"
@import CoreBluetooth;

#ifdef DEBUG
#   define ConnectionLog(fmt, ...) if (YES) { NSLog((fmt), ##__VA_ARGS__); }
#endif

@interface PPConnectionCoreManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)startConnectionWithPeripheral:(PPPeripheral *)peripheral;

- (void)disconnectDevice;

@property (nonatomic) CGFloat maxConnectionTime;
@property (nonatomic) BOOL shouldRetryAfterDisconnection;
@property (nonatomic) BOOL enableLogging;

@property (nonatomic, readonly, strong) PPPeripheral *connectedPeripheral;
@property (nonatomic, readonly, strong) PPConfiguration *configuration;
// callbacks
@property (nonatomic, copy) void(^onDisconnectionHandler)(NSError *error);
@property (nonatomic, copy) void(^errorHandler)(NSError *error);
@property (nonatomic, copy) void(^bluetoothStateHandler)(NSError *error);
@property (nonatomic, copy) BOOL(^onDiscoveryHandler)(NSDictionary *advertisement, NSString *peerUUID);
@property (nonatomic, copy) BOOL(^onConnectedHandler)(void);
@property (nonatomic, copy) BOOL(^onServicesDiscoveryHandler)(NSArray *services);
@property (nonatomic, copy) BOOL(^onCharacteristicsDiscoveryHandler)(NSArray *characteristics, CBService *service);
@property (nonatomic, copy) void(^onCompleteConnectionHandler)(CBPeripheral *peripheral);

@end
