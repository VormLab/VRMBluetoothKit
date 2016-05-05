//
//  PPConnectionErrorBuilder.m
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

#import "PPErrorBuilder.h"

static NSString *domain = @"PPBluetoothKitError";

static NSString *disconnection_description = @"The connection quit unexpectedly";
static NSString *bluetooth_off = @"The bluetooth module is off (CBCentralManagerStatePoweredOff)";
static NSString *bluetooth_resetting = @"The bluetooth module is resetting (CBCentralManagerStateResetting)";
static NSString *bluetooth_unathorized = @"The bluetooth module is unathorized (CBCentralManagerStateUnauthorized)";
static NSString *bluetooth_unsupported = @"This device does not support Bluetoth 4.0.";
static NSString *bluetooth_unknown = @"Bluetooth state is unknown (CBCentralManagerStateUnknown)";
static NSString *wrong_format_configurtaion = @"Check the data input format when configurin PPConnectionConfiguration class";
static NSString *no_device_error = @"Before writing values, you must first connect to the device using PPConnection class.";

static NSString *writing_to_readonly = @"You are trying to write to characteristic that is read-only.";
static NSString *reading_from_writeonly = @"You are trying to read from characteristic that is write-only.";

@implementation PPErrorBuilder

+ (NSError *)errorForBluetoothCentralState:(CBCentralManagerState)state {
    switch (state) {
        case CBCentralManagerStatePoweredOff:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothOff];
            break;
        case CBCentralManagerStateResetting:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothResetting];
            break;
        case CBCentralManagerStateUnauthorized:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnauthorized];
            break;
        case CBCentralManagerStateUnsupported:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnsupported];
            break;
        case CBCentralManagerStateUnknown:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnknown];
            break;
        default:
            break;
    }
    return nil;
}

+ (NSError *)errorForBluetoothPeripheralState:(CBPeripheralManagerState)state {
    switch (state) {
        case CBPeripheralManagerStatePoweredOff:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothOff];
            break;
        case CBPeripheralManagerStateResetting:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothResetting];
            break;
        case CBPeripheralManagerStateUnauthorized:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnauthorized];
            break;
        case CBPeripheralManagerStateUnsupported:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnsupported];
            break;
        case CBPeripheralManagerStateUnknown:
            return [PPErrorBuilder errorForType:ErrorTypeBluetoothUnknown];
            break;
        default:
            break;
    }
    return nil;
}

+ (NSError *)wrongConfigurationInputFormatError {
    
    return [PPErrorBuilder errorForType:ErrorTypeWrongInputFormat];
}

+ (NSError *)noDeviceConnectedError {
    
    return [PPErrorBuilder errorForType:ErrorTypeNoDevice];
}

+ (NSError *)disconnectionError {
    
    return [PPErrorBuilder errorForType:ErrorTypeDisconnection];
}

+ (NSError *)readingFromWriteOnlyError {
    
    return [PPErrorBuilder errorForType:ErrorTypeWrongReadPermission];
}

+ (NSError *)writingToReadOnlyError {
    
    return [PPErrorBuilder errorForType:ErrorTypeWrongWritePermission];
}

//////////////////////////////////////////////////////////////////////////////////////////
// Helpers//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


+ (NSError *)errorForType:(ErrorType)type {
    switch (type) {
        case ErrorTypeBluetoothOff:
            return [PPErrorBuilder createError:type message:bluetooth_off];
            break;
        case ErrorTypeBluetoothResetting:
            return [PPErrorBuilder createError:type message:bluetooth_resetting];
            break;
        case ErrorTypeBluetoothUnauthorized:
            return [PPErrorBuilder createError:type message:bluetooth_unathorized];
            break;
        case ErrorTypeBluetoothUnknown:
            return [PPErrorBuilder createError:type message:bluetooth_unknown];
            break;
        case ErrorTypeBluetoothUnsupported:
            return [PPErrorBuilder createError:type message:bluetooth_unsupported];
            break;
        case ErrorTypeDisconnection:
            return [PPErrorBuilder createError:type message:disconnection_description];
            break;
        case ErrorTypeWrongInputFormat:
            return [PPErrorBuilder createError:type message:wrong_format_configurtaion];
            break;
        case ErrorTypeNoDevice:
            return [PPErrorBuilder createError:type message:no_device_error];
            break;
        case ErrorTypeWrongReadPermission:
            return [PPErrorBuilder createError:type message:reading_from_writeonly];
            break;
        case ErrorTypeWrongWritePermission:
            return [PPErrorBuilder createError:type message:writing_to_readonly];
            break;
        default:
            break;
    }
    return nil;
}

+ (NSError *)createError:(ErrorType)type message:(NSString *)message {
    NSError *error = [NSError errorWithDomain:domain code:type userInfo:[PPErrorBuilder errorUserInfoWithMessage:message]];
    return error;
}

+ (NSDictionary *)errorUserInfoWithMessage:(NSString *)message {
    return @{NSLocalizedDescriptionKey : message};
}

@end
