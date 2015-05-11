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

#include "MTypes.h"

#ifdef __APPLE_CC__
#include <Accelerate/Accelerate.h>
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

#include <math.h>

#pragma mark static inline creators

static inline MPlane MMakePlane(float a, float b, float c, float d)
{
	MPlane v;
	v.normal.x = a;
	v.normal.y = b;
	v.normal.z = c;
	v.d = d;
	return v;
}

static inline MVec3 MMakeVec3(float x, float y, float z)
{
	MVec3 v;
	v.x = x;
	v.y = y;
	v.z = z;
	return v;
}

static inline MSphere MMakeSphere(float x, float y, float z, float radius)
{
	MSphere s;
	s.center.x = x;
	s.center.y = y;
	s.center.z = z;
	s.radius = radius;
	return s;
}

#pragma mark Utilities

static inline MVec3 MVecAdd(MVec3 a, MVec3 b)
{
	MVec3 result;
	result.x = a.x + b.x;
	result.y = a.y + b.y;
	result.z = a.z + b.z;
	return result;
}

static inline MVec3 MVecSub(MVec3 a, MVec3 b)
{
	MVec3 result;
	result.x = a.x - b.x;
	result.y = a.y - b.y;
	result.z = a.z - b.z;
	return result;
}

static inline MVec3 MVecScale(MVec3 vec, float factor)
{
	MVec3 result;
	result.x = vec.x * factor;
	result.y = vec.y * factor;
	result.z = vec.z * factor;	
	return result;
}

static inline float MVecDot(MVec3 a, MVec3 b)
{
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

static inline float MVecInverseLength(MVec3 vec)
{
	return 1.0f / sqrtf(MVecDot(vec, vec));
}

static inline float MVecLength(MVec3 vec)
{
	return sqrtf(MVecDot(vec, vec));
}

static inline MVec3 MVecCross(MVec3 a, MVec3 b)
{
	MVec3 result;
	result.x = a.y * b.z - a.z * b.y;
	result.y = a.z * b.x - a.x * b.z;
	result.z = a.x * b.y - a.y * b.x;
	return result;
}

static inline void MVecNormalize(MVec3 *vec)
{
	float length = MVecInverseLength(*vec);
	vec->x *= length;
	vec->y *= length;
	vec->z *= length;
}


static inline MVec3 MVecInterpolate(MVec3 *vecs, unsigned vecCount)
{
	unsigned i;
	MVec3 result = MMakeVec3(0.0f, 0.0f, 0.0f);
	for (i = 0; i < vecCount; i++)
	{
		result.x += vecs[i].x / (float) vecCount;
		result.y += vecs[i].y / (float) vecCount;
		result.z += vecs[i].z / (float) vecCount;
	}
	return result;
}

static inline void MQuaternionNormalize(MQuaternion *quat)
{
	float mag = quat->x * quat->x + quat->y * quat->y + quat->z * quat->z + quat->w * quat->w;
	
	mag = sqrtf(mag);
	
	quat->x /= mag;
	quat->y /= mag;
	quat->z /= mag;
	quat->w /= mag;
}

static inline MQuaternion MQuaternionFromAxisAngle(MVec3 axis, float angle)
{
	MQuaternion result;
	float sinAngle;
	
	angle *= 0.5f;
	sinAngle = sin(angle);
	result.x = (axis.x * sinAngle);
	result.y = (axis.y * sinAngle);
	result.z = (axis.z * sinAngle);
	result.w = cos(angle);
	return result;
}

static inline void MQuaternionToAxisAngle(MQuaternion quat, MVec3 *axis, float *angle)
{
	float sinAngle;
	
	MQuaternionNormalize(&quat);
	sinAngle = sqrt(1.0f - (quat.w * quat.w));
	if (fabs(sinAngle) < 0.0005f) sinAngle = 1.0f;
	axis->x = (quat.x / sinAngle);
	axis->y = (quat.y / sinAngle);
	axis->z = (quat.z / sinAngle);
	*angle = (acos(quat.w) * 2.0f);
}

static inline void MQuaternionInvert(MQuaternion *quat)
{	
	float length;
	
	length = (1.0f / ((quat->x * quat->x) +
						(quat->y * quat->y) +
						(quat->z * quat->z) +
						(quat->w * quat->w)));
	quat->x *= -length;
	quat->y *= -length;
	quat->z *= -length;
	quat->w *= length;
}

static inline MQuaternion MQuaternionMultiply(const MQuaternion *quat1, const MQuaternion *quat2)
{
	MQuaternion result;
	
	result.x = quat1->x * quat2->w + quat2->x * quat1->w + quat1->y * quat2->z - quat1->z * quat2->y;
	result.y = quat1->y * quat2->w + quat2->y * quat1->w + quat1->z * quat2->x - quat1->x * quat2->z;
	result.z = quat1->z * quat2->w + quat2->z * quat1->w + quat1->x * quat2->y - quat1->y * quat2->x;
	result.w = quat1->w * quat2->w - quat1->x * quat2->x - quat1->y * quat2->y - quat1->z * quat2->z;
	
	return result;
}

static inline MVec3 MQuaternionVecMultiply(MQuaternion *quat, MVec3 *vector)
{
	MQuaternion vectorQuat, inverseQuat, resultQuat;
	MVec3 resultVector;
	
	vectorQuat.x = vector->x;
	vectorQuat.y = vector->y;
	vectorQuat.z = vector->z;
	vectorQuat.w = 0.0f;
	
	inverseQuat = *quat;
	MQuaternionInvert(&inverseQuat);
	
	resultQuat = MQuaternionMultiply(quat, &vectorQuat);
	resultQuat = MQuaternionMultiply(&resultQuat, &inverseQuat);
	
	resultVector.x = resultQuat.x;
	resultVector.y = resultQuat.y;
	resultVector.z = resultQuat.z;
	
	return resultVector;
}

static inline void MPlaneInvert(MPlane *plane)
{
	(*plane).normal.x *= -1.0f;
	(*plane).normal.y *= -1.0f;
	(*plane).normal.z *= -1.0f;
	(*plane).d *= -1.0f;
}

static inline void MPlaneNormalize(MPlane *plane)
{
	float length = MVecInverseLength(plane->normal);
	(*plane).normal.x *= length;
	(*plane).normal.y *= length;
	(*plane).normal.z *= length;
	(*plane).d *= length;
}

static inline float MPlaneVecMultiply(MPlane plane, MVec3 vec)
{
	return MVecDot(plane.normal, vec) + plane.d;
}

static inline MVec3 MVecMatrixTransform(MVec3 vector, MMatrix matrix)
{
	MVec3 transformed;
	transformed.x = matrix.direct[0] * vector.x + matrix.direct[4] * vector.y + matrix.direct[8] * vector.z + matrix.direct[12];
	transformed.y = matrix.direct[1] * vector.x + matrix.direct[5] * vector.y + matrix.direct[9] * vector.z + matrix.direct[13]; 
	transformed.z = matrix.direct[2] * vector.x + matrix.direct[6] * vector.y + matrix.direct[10] * vector.z + matrix.direct[14];
	return transformed; 
}

static inline MVec3 MVecMatrixRotate(MVec3 vector, MMatrix matrix)
{
	MVec3 transformed;
	transformed.x = matrix.direct[0] * vector.x + matrix.direct[4] * vector.y + matrix.direct[8] * vector.z;
	transformed.y = matrix.direct[1] * vector.x + matrix.direct[5] * vector.y + matrix.direct[9] * vector.z; 
	transformed.z = matrix.direct[2] * vector.x + matrix.direct[6] * vector.y + matrix.direct[10] * vector.z;
	return transformed; 
}

static inline MMatrix MMatrixIdentity(void)
{
	MMatrix result = {1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f};
	return result;
}

static inline MMatrix MMatrixRotationInverse(MMatrix matrix)
{
	MMatrix result = MMatrixIdentity();
	result.direct[0] = matrix.direct[0]; result.direct[4] = matrix.direct[1]; result.direct[8] = matrix.direct[2];
	result.direct[1] = matrix.direct[4]; result.direct[5] = matrix.direct[5]; result.direct[9] = matrix.direct[6];
	result.direct[2] = matrix.direct[8]; result.direct[6] = matrix.direct[9]; result.direct[10] = matrix.direct[10];
	return result;
}
static inline MMatrix MMatrixInverse(MMatrix matrix)
{
	MMatrix result = MMatrixRotationInverse(matrix);
	result.vectors.position.x = - MVecDot(matrix.vectors.x, matrix.vectors.position);
	result.vectors.position.y = - MVecDot(matrix.vectors.y, matrix.vectors.position);
	result.vectors.position.z = - MVecDot(matrix.vectors.z, matrix.vectors.position);
	return result;
}

static inline MMatrix MMatrixMultiply(MMatrix a, MMatrix b)
{
	MMatrix result;
#if defined __APPLE_CC__
	vDSP_mmul(a.direct, 1, b.direct, 1, result.direct, 1, 4, 4, 4);
#else
#error Too lazy to do generic stuff
#endif
	return result;
}
static inline MMatrix MMatrixYaw(float angle)
{
	angle *= M_PI / 180.0f;
	float cosine = cos(angle);
	float sine = sin(angle);
	
	MMatrix result;
	result.vectors.x.x = cosine; result.vectors.x.y = 0.0f; result.vectors.x.z = -sine; result.vectors.x_w = 0.0f;
	result.vectors.y.x = 0.0f; result.vectors.y.y = 1.0f; result.vectors.y.z = 0.0f; result.vectors.y_w = 0.0f;
	result.vectors.z.x = sine; result.vectors.z.y = 0.0f; result.vectors.z.z = cosine; result.vectors.z_w = 0.0f;
	result.vectors.position.x = 0.0f; result.vectors.position.y = 0.0f; result.vectors.position.z = 0.0f; result.vectors.position_w = 1.0f;
	return result;
}

#pragma mark Frustum Tests

static inline int MSpheresIntersect(MSphere a, MSphere b)
{
	MVec3 vector = MVecSub(a.center, b.center);
	return (MVecDot(vector, vector) < ((a.radius + b.radius) * (a.radius + b.radius)));
}

static inline int MLinePlaneIntersection(MVec3 pointA, MVec3 pointB, MPlane plane, MVec3 *pointHere)
{
	MVec3 direction = MVecSub(pointB, pointA);
	if (fabsf(MVecDot(direction, plane.normal)) < 0.001f) return 0;
	
	// Gerade ist pointA + t * direction;
//	(pointA + t * direction) * plane.normal + plane.d = 0;
//	pointA * plane.normal + t * direction * plane.normal + plane.d = 0;
//	t * direction * plane.normal = -(plane.d + pointA * plane.normal);
//	t = -(plane.d + pointA * plane.normal) / direction * plane.normal;
		
	float t = -MPlaneVecMultiply(plane, pointA)/ (MVecDot(direction, plane.normal));
	if ((t < 0.0f) || (t > 1.0f)) return 0;
	
	*pointHere = MVecAdd(pointA, MVecScale(direction, t));
	return 1;
}

static inline MPlane MPlaneFromPoints(MVec3 a, MVec3 b, MVec3 c)
{
	// First, get two direction vectors
	MVec3 dir1 = MVecSub(b, a);
	MVec3 dir2 = MVecSub(c, a);
	
	MPlane result;
	result.normal = MVecCross(dir1, dir2);
	result.d = -1.0f * MVecDot(result.normal, a);
	
	return result;
}

static inline MPlane MPlaneFromDirectionAndPoint(MVec3 direction, MVec3 point)
{
	MPlane result;
	result.normal = direction;
	result.d = -1.0f * MVecDot(direction, point);
	return result;
}

// Returns 1 on all in, 0 on some in, -1 on none in
/*static inline*/ int MVertexCloudWithinPlanes(MVec3 box[], unsigned vertexCount, MPlane planes[], unsigned planeCount)
/*{
	#ifdef __OBJC__
	NSLog(@"MVertexCloudWithinPlanes(%p, %u, %p, %u);", box, vertexCount, planes, planeCount);
	#endif
	int incount = 0;
	int i, j;
	for (i = 0; i < planeCount; ++i)
	{
		int planeIn = vertexCount; // Zählt, wie viele der Punkte auf der richtigen Seite der Ebene liegen
		for (j = 0; j < vertexCount; ++j)
		{
			if (MPlaneVecMultiply(planes[i], box[j]) < 0.0f)
				planeIn -= 1;
		}
		
		if (planeIn == 0) return -1;
		if (planeIn == vertexCount) incount += 1;
	}
	
	if (incount == planeCount) return 1;
	else return 0;
}*/;

#pragma mark Cocoa-only Functions

#ifdef __OBJC__

static inline NSString *MStringFromMatrix(MMatrix matrix)
{
	return [NSString stringWithFormat:@"{x={%f, %f, %f,%f}, y={%f, %f, %f,%f}, z={%f, %f, %f,%f}, position={%f, %f, %f,%f}}", matrix.direct[0], matrix.direct[1], matrix.direct[2], matrix.direct[3], matrix.direct[4], matrix.direct[5], matrix.direct[6], matrix.direct[7], matrix.direct[8], matrix.direct[9], matrix.direct[10], matrix.direct[11], matrix.direct[12], matrix.direct[13], matrix.direct[14], matrix.direct[15]];
}

static inline NSString *MStringFromVec(MVec3 vector)
{
	return [NSString stringWithFormat:@"{x=%f, y=%f, z=%f}", vector.x, vector.y, vector.z];
}

static inline NSString *MStringFromPlane(MPlane plane)
{
	return [NSString stringWithFormat:@"{normal={x=%f, y=%f, z=%f}, d=%f}", plane.normal.x, plane.normal.y, plane.normal.z, plane.d];
}

#endif

#pragma mark More Serious work

MSphere MSphereUnion(MSphere a, MSphere b);
MSphere MSpheresUnion(MSphere spheres[], unsigned sphereCount);
MVec3 MPlaneIntersection(MPlane a, MPlane b, MPlane c);

void MGetOpenGLViewFrustum(MPlane outPlanes[6]);
void MGetOpenGLViewFrustumStoredProjectionMatrix(MPlane outPlanes[6], MMatrix projectionMatrix);