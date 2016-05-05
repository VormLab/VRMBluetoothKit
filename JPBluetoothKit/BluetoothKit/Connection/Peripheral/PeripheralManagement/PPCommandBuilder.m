//
//  PPCommandBuilder.m
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

#import "PPCommandBuilder.h"
#import "PPUtility.h"

static NSInteger defaultChunkSize = 20;

@implementation PPCommandBuilder

#pragma mark - integer commands

+ (PPCommand *)int8CommandWithValue:(uint8_t)value forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[PPUtility dataFrom8bitInteger:value] characteristic:characteristic];
    return command;
}

+ (PPCommand *)int16CommandWithValue:(uint16_t)value forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[PPUtility dataFrom16bitInteger:value] characteristic:characteristic];
    return command;
}

+ (PPCommand *)int32CommandWithValue:(uint32_t)value forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[PPUtility dataFrom32bitInteger:value] characteristic:characteristic];
    return command;
}

+ (PPCommand *)int64CommandWithValue:(uint64_t)value forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[PPUtility dataFrom64bitInteger:value] characteristic:characteristic];
    return command;
}

#pragma mark - string commands

+ (PPCommand *)hexStringCommandWithValue:(NSString *)value forCharacteristic:(PPCharacteristic *)characteristic {
    //TODO: sprawdzic, czy to dziala
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[PPUtility bytesFromHexString:value] characteristic:characteristic];
    return command;
}

+ (PPCommand *)utfStringCommandWithValue:(NSString *)value forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:[value dataUsingEncoding:NSUTF8StringEncoding] characteristic:characteristic];
    return command;
}

#pragma mark - raw command

+ (PPCommand *)rawCommand:(NSData *)data forCharacteristic:(PPCharacteristic *)characteristic {
    PPCommand *command = [[PPCommand alloc] initWithCommandBody:data characteristic:characteristic];
    return command;
}

#pragma mark - multipart commands

+ (PPMultipartCommand *)mutlipartCommand:(NSData *)data forCharacteristic:(PPCharacteristic *)characteristic maximumChunkSize:(NSInteger)bytes {
    PPMultipartCommand *command = [[PPMultipartCommand alloc] initWithData:data chunkSize:bytes ? bytes : defaultChunkSize forCharacteristic:characteristic];
    return command;
}

@end
