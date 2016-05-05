//
//  PPUtility.m
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

#import "PPUtility.h"
#import "PPErrorBuilder.h"

@implementation PPUtility

+ (CBUUID *)normalizedUUID:(id)uuid error:(NSError **)error {
    if ([uuid isKindOfClass:[CBUUID class]]) {
        return (CBUUID *)uuid;
    }
    else if ([uuid isKindOfClass:[NSString class]]) {
        return [CBUUID UUIDWithString:(NSString *)uuid];
    }
    else if ([uuid isKindOfClass:[NSUUID class]]) {
        return [CBUUID UUIDWithString:((NSUUID *)uuid).UUIDString];
    }
    *error = [PPErrorBuilder wrongConfigurationInputFormatError];
    return nil;
}

+ (NSData *)dataFrom8bitInteger:(uint8_t)integer {
    NSData *data = [NSData dataWithBytes:&integer length:sizeof(integer)];
    return data;
}

+ (NSData *)dataFrom16bitInteger:(uint16_t)integer {
    NSData *data = [NSData dataWithBytes:&integer length:sizeof(integer)];
    return data;
}

+ (NSData *)dataFrom32bitInteger:(uint32_t)integer {
    NSData *data = [NSData dataWithBytes:&integer length:sizeof(integer)];
    return data;
}

+ (NSData *)dataFrom64bitInteger:(uint64_t)integer {
    NSData *data = [NSData dataWithBytes:&integer length:sizeof(integer)];
    return data;
}

+ (NSData*)bytesFromHexString:(NSString *)aString {
    
    NSString *theString = [[aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= theString.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [theString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        if ([scanner scanHexInt:&intValue])
            [data appendBytes:&intValue length:1];
    }
    return data;
}

+ (NSArray *)splittedDataChunksFrom:(NSData *)data chunkSize:(NSInteger)size {

    NSMutableArray *chunks = [NSMutableArray new];
    NSUInteger length = [data length];
    NSUInteger chunkSize = size;
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        [chunks addObject:chunk];
    } while (offset < length);
    return [chunks copy];
}

@end
