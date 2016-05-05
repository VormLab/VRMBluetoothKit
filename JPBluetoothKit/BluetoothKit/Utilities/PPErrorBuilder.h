//
//  PPConnectionErrorBuilder.h
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
@import CoreBluetooth;

typedef NS_ENUM(NSInteger) {
    
    ErrorTypeBluetoothOff               = 101,
    ErrorTypeBluetoothResetting         = 102,
    ErrorTypeBluetoothUnauthorized      = 103,
    ErrorTypeBluetoothUnsupported       = 104,
    ErrorTypeBluetoothUnknown           = 105,
    
    ErrorTypeDisconnection              = 200,
    ErrorTypeNoDevice                   = 201,
    
    ErrorTypeWrongWritePermission       = 300,
    ErrorTypeWrongReadPermission        = 301,
    
    ErrorTypeWrongInputFormat           = 400
    
} ErrorType;

@interface PPErrorBuilder : NSObject

+ (NSError *)errorForBluetoothCentralState:(CBCentralManagerState)state;

+ (NSError *)errorForBluetoothPeripheralState:(CBPeripheralManagerState)state;

+ (NSError *)wrongConfigurationInputFormatError;

+ (NSError *)noDeviceConnectedError;

+ (NSError *)disconnectionError;

+ (NSError *)writingToReadOnlyError;

+ (NSError *)readingFromWriteOnlyError;

@end
