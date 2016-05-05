//
//  JPConnection.h
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

#import <UIKit/UIKit.h>
#import "PPPeripheral.h"

typedef NS_ENUM(NSInteger) {
    ConnectionStateNone,
    ConnectionStateError,
    ConnectionStateSearching,
    ConnectionStateConnecting,
    ConnectionStateValidating,
    ConnectionStateComplete
} ConnectionState;

@interface PPConnection : NSObject

+ (PPConnection *)defaultConnection;

- (void)connectDevice:(PPPeripheral *)peripheral    connectionStateHandler:(void(^)(ConnectionState state))connectionStateHandler
                                                    completionHandler:(void(^)(BOOL completed, NSError *error))handler;

- (void)connectDevice:(PPPeripheral *)peripheral    completionHandler:(void(^)(BOOL completed, NSError *error))handler;

- (void)disconnectDevice:(PPPeripheral *)device;

@property (nonatomic, readonly, strong) PPPeripheral *connectingPeripheral;

// defines maximum time for connection to last. If it's too long, timer kills it and consider as filed. Than tries again. Defaults to 5 seconds.
@property (nonatomic) CGFloat maximumConnectionTime;

// defines if peripheral should contain every service and characteristic from configuration class to be connected properly. Defaults to YES.
// If turned to NO, peripheral would be connected if at least one service and ona characteristic in each service matches passed values.
// Matters only if you do not implement your own characteristics/services validation handlers.
@property (nonatomic) BOOL deviceShouldContainAllConfigurationData;

// turns on some useful connection logs diplaying device's advertising, characteristics etc. Defaults to NO.
@property (nonatomic) BOOL enableLogging;

// define to sepcify if you want to try to connect again to the device after disconnection. Defaults to YES.
@property (nonatomic) BOOL shouldRetryAfterDisconnection;

// use to check if advertising or peripheral identifier matches desired ones. If NO returned, deviced will not proceed futher connection.
@property (nonatomic, copy) BOOL(^preconnectionValidationHandler)(NSString *peripheralIdentifier, NSDictionary *advertisementData, PPPeripheral *peripheral);

// use to implement your own services identification. By default, further connection is proceeded only if peripheral contains all passed services.
// FIXME: change to PPService, PPCharacteristic
@property (nonatomic, copy) BOOL(^servicesValidationHandler)(NSArray *characteristics, PPPeripheral *peripheral);

// use to implement your own characteristics identification. By default, further connection is proceeded only if every service contains all passed characteristics.
// FIXME: change to PPService, PPCharacteristic
@property (nonatomic, copy) BOOL(^characteristicsValidationHandler)(NSArray *characteristics, CBService *service, PPPeripheral *peripheral);

@property (nonatomic, readonly) ConnectionState currentConnectionState;

@end
