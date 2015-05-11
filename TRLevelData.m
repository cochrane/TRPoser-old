//
//  TRLevelData.m
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

#import "TRLevelData.h"
#import <zlib.h>

@implementation TRLevelData

- (id)initWithData:(NSData *)data;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	if (!data)
	{
		[self release];
		return nil;
	}
	
	levelData = [data copy];
	dataIndex = 0;
	
	return self;
}

- (void)dealloc
{
	[levelData release];
	[super dealloc];
}

- (uint32_t)readUint32;
{
	uint32_t result = 0;
	[self readUint32Array:&result count:1];
	return result;
}
- (uint16_t)readUint16;
{
	uint16_t result = 0;
	[self readUint16Array:&result count:1];
	return result;
}
- (uint8_t)readUint8;
{
	uint8_t result = 0;
	[self readUint8Array:&result count:1];
	return result;
}
- (Float32)readFloat32;
{
	Float32 result = 0.0f;
	[self readFloat32Array:&result count:1];
	return result;
}
- (int32_t)readInt32;
{
	int32_t result = 0;
	[self readUint32Array:(uint32_t *) &result count:1];
	return result;
}

- (int16_t)readInt16;
{
	int16_t result = 0;
	[self readUint16Array:(uint16_t *) &result count:1];
	return result;
}

- (int8_t)readInt8;
{
	int8_t result = 0;
	[self readUint8Array:(uint8_t *) &result count:1];
	return result;
}

- (void)readUint32Array:(uint32_t *)array count:(unsigned)count;
{
	if ([self isAtEnd]) return;
	if (dataIndex + count*4 > [levelData length]) return;
	
	[levelData getBytes:array range:NSMakeRange(dataIndex, count * 4)];
	unsigned i;
	for (i = 0; i < count; i++)
		array[i] = NSSwapLittleIntToHost(array[i]);
		
	dataIndex += count * 4;
}

- (void)readUint16Array:(uint16_t *)array count:(unsigned)count;
{
	if ([self isAtEnd]) return;
	if (dataIndex + count*2 > [levelData length]) return;
	
	[levelData getBytes:array range:NSMakeRange(dataIndex, count * 2)];
	unsigned i;
	for (i = 0; i < count; i++)
		array[i] = NSSwapLittleShortToHost(array[i]);
		
	dataIndex += count * 2;
}

- (void)readUint8Array:(uint8_t *)array count:(unsigned)count;
{
	if ([self isAtEnd]) return;
	if (dataIndex + count > [levelData length]) return;
	
	NSRange range = NSMakeRange(dataIndex, count);
	[levelData getBytes:array range:range];
	
	dataIndex += count;
}

- (void)readFloat32Array:(Float32 *)array count:(unsigned)count;
{
	uint32_t *uint32array = (uint32_t *) array;
	[self readUint32Array:uint32array count:count];
}

- (unsigned)position;
{
	return dataIndex;
}
- (void)setPosition:(unsigned)byte;
{
	dataIndex = byte;
}

- (void)skipBytes:(unsigned)count;
{
	dataIndex += count;
}
- (void)skipField16:(unsigned)elementWidth;
{
	unsigned fieldLength = (unsigned) [self readUint16];

	[self skipBytes:fieldLength * elementWidth];
}
- (void)skipField32:(unsigned)elementWidth;
{
	unsigned fieldLength = (unsigned) [self readUint32];

	[self skipBytes:fieldLength * elementWidth];
}

- (TRLevelData *)decompressLevelDataCompressedLength:(unsigned)actualBytes uncompressedLength:(unsigned)originalBytes;
{
	uint8_t *uncompressedData = malloc(originalBytes);
	uint8_t *compressedData = malloc(actualBytes);
	[self readUint8Array:compressedData count:actualBytes];
	
	unsigned uncompressedLength = originalBytes;
	
	int result = uncompress(uncompressedData, (uLongf *) &uncompressedLength, compressedData, actualBytes);
	if (result != Z_OK) [NSException raise:NSInternalInconsistencyException format:@"ZLib encountered error %i", result];
	
	if (uncompressedLength < originalBytes) [NSException raise:NSInternalInconsistencyException format:@"Not all data could be decompressed, only uncompressed %u bytes", uncompressedLength];
	
	NSData *data = [NSData dataWithBytes:uncompressedData length:originalBytes];
	id resultLevelData = [[TRLevelData alloc] initWithData:data];
	[resultLevelData autorelease];
	
	free(compressedData);
	free(uncompressedData);
	
	return resultLevelData;
}
- (TRLevelData *)subdataWithLength:(unsigned)bytes;
{
	NSData *underlyingData = [levelData subdataWithRange:NSMakeRange(dataIndex, bytes)];
	TRLevelData *result = [[TRLevelData alloc] initWithData:underlyingData];
	[result autorelease];
	dataIndex += bytes;
	return result;
}

- (BOOL)isAtEnd;
{
	return (dataIndex >= [levelData length]);
}

@end
