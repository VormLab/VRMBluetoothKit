//
//  VRMCommandBuilder.m
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

#import "VRMCommandBuilder.h"
#import "VRMUtility.h"

static NSInteger defaultChunkSize = 20;

@implementation VRMCommandBuilder

#pragma mark - integer commands

+ (VRMCommand *)int8CommandWithValue:(uint8_t)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[VRMUtility dataFrom8bitInteger:value] characteristic:characteristic];
    return command;
}

+ (VRMCommand *)int16CommandWithValue:(uint16_t)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[VRMUtility dataFrom16bitInteger:value] characteristic:characteristic];
    return command;
}

+ (VRMCommand *)int32CommandWithValue:(uint32_t)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[VRMUtility dataFrom32bitInteger:value] characteristic:characteristic];
    return command;
}

+ (VRMCommand *)int64CommandWithValue:(uint64_t)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[VRMUtility dataFrom64bitInteger:value] characteristic:characteristic];
    return command;
}

#pragma mark - string commands

+ (VRMCommand *)hexStringCommandWithValue:(NSString *)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[VRMUtility bytesFromHexString:value] characteristic:characteristic];
    return command;
}

+ (VRMCommand *)utfStringCommandWithValue:(NSString *)value forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:[value dataUsingEncoding:NSUTF8StringEncoding] characteristic:characteristic];
    return command;
}

#pragma mark - raw command

+ (VRMCommand *)rawCommand:(NSData *)data forCharacteristic:(VRMCharacteristic *)characteristic {
    VRMCommand *command = [[VRMCommand alloc] initWithCommandBody:data characteristic:characteristic];
    return command;
}

#pragma mark - multipart commands

+ (VRMMultipartCommand *)mutlipartCommand:(NSData *)data forCharacteristic:(VRMCharacteristic *)characteristic maximumChunkSize:(NSInteger)bytes {
    VRMMultipartCommand *command = [[VRMMultipartCommand alloc] initWithData:data chunkSize:bytes ? bytes : defaultChunkSize forCharacteristic:characteristic];
    return command;
}

@end
