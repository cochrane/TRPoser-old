//
//  TRLevelData.h
//  TRViewer
//
//  Created by Torsten Kammer on 29.05.06.
//  Copyright 2006 Ferroequinologist.de. All rights reserved.
//
/*
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * This file is part of TR Poser.
 *
 */

#import <Cocoa/Cocoa.h>

//static NSString *TRLevelDataDecompressionErrorException = @"TR Level Data decompression exception";
//static NSString *TRLevelZlibReturnValueKey = @"Zlib return value";
//static NSString *TRLevelDataDecompressedLengthKey = @"Length of decompressed data";
//static NSString *TRLevelIndexKey = @"Value of index out of bound";
//static NSString *TRLevelMaxValueKey = @"Allowed maximum value";

@interface TRLevelData : NSObject
{
	NSData *levelData;
	unsigned dataIndex;
}

- (id)initWithData:(NSData *)data;

- (uint32_t)readUint32;
- (uint16_t)readUint16;
- (uint8_t)readUint8;
- (Float32)readFloat32;
- (int32_t)readInt32;
- (int16_t)readInt16;
- (int8_t)readInt8;

- (void)readUint32Array:(uint32_t *)array count:(unsigned)count;
- (void)readUint16Array:(uint16_t *)array count:(unsigned)count;
- (void)readUint8Array:(uint8_t *)array count:(unsigned)count;
- (void)readFloat32Array:(Float32 *)array count:(unsigned)count;

- (unsigned)position;
- (void)setPosition:(unsigned)byte;

- (void)skipBytes:(unsigned)count;
- (void)skipField16:(unsigned)elementWidth;
- (void)skipField32:(unsigned)elementWidth;

- (TRLevelData *)decompressLevelDataCompressedLength:(unsigned)actualBytes uncompressedLength:(unsigned)originalBytes;
- (TRLevelData *)subdataWithLength:(unsigned)bytes;

- (BOOL)isAtEnd;

@end
