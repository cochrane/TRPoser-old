/*
 *  MMath.h
 *  Snow
 *
 *  Created by Torsten Kammer on 02.02.06.
 *  Copyright 2006 Ferroequinologist.de. All rights reserved.
 *
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

#ifndef MTYPES_H_
#define MTYPES_H_

typedef struct
{
	float x;
	float y;
	float z;
} MVec3;

typedef struct
{
	float x;
	float y;
	float z;
	float w;
} MQuaternion;

typedef struct
{
	MVec3 normal;
	float d;
} MPlane;

typedef struct
{
	MVec3 center;
	float radius;
} MSphere;

typedef union
{
	float direct[16];
	struct
	{
		MVec3 x;
		float x_w;
		MVec3 y;
		float y_w;
		MVec3 z;
		float z_w;
		MVec3 position;
		float position_w;
	} vectors;
	struct
	{
		float _11, _21, _31, _41;
		float _12, _22, _32, _42;
		float _13, _23, _33, _43;
		float _14, _24, _34, _44;
	} single;
}
MMatrix;

#endif