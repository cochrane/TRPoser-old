/*
 *  TRRawViewCam.c
 *  TRViewer
 *
 *  Created by Torsten on 16.03.06.
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

#include "TRRawViewCam.h"
#include <OpenGL/gl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#pragma mark Mathematik
struct Quaternion {
	float x;
	float y;
	float z;
	float w;
};
typedef struct Quaternion Quaternion;

struct Vector
{
	float x;
	float y;
	float z;
};
typedef struct Vector Vector;

inline Vector VectorCreate(float x, float y, float z)
{
	Vector v;
	v.x = x;
	v.y = y;
	v.z = z;
	return v;
}

inline float VectorDot(Vector v1, Vector v2)
{
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

inline Vector VectorCross(Vector v1, Vector v2)
{
	Vector cross;
	cross.x = v1.y * v2.z - v1.z * v2.y;
	cross.y = v1.z * v2.x - v1.x * v2.z;
	cross.z = v1.x * v2.y - v1.y * v2.x;
	return cross;
}
inline void VectorNormalize(Vector *vec)
{
	float length = 1.0f / sqrtf(VectorDot(*vec, *vec));
	vec->x *= length;
	vec->y *= length;
	vec->z *= length;
}

inline Quaternion QuaternionCopy(Quaternion original)
{
	Quaternion q;
	q.x = original.x;
	q.y = original.y;
	q.z = original.z;
	q.w = original.w;
	return q;
}

void QuaternionNormalize(Quaternion * quat)
{
	float magnitude;
	
	magnitude = sqrt((quat->x * quat->x) + (quat->y * quat->y) + (quat->z * quat->z) + (quat->w * quat->w));
	quat->x /= magnitude;
	quat->y /= magnitude;
	quat->z /= magnitude;
	quat->w /= magnitude;
}

Quaternion QuaternionFromAxisAngle(Vector axis, float angle)
{
	Quaternion result;
	float sinAngle;
	
	angle *= 0.5f;
	VectorNormalize(&axis);
	sinAngle = sin(angle);
	result.x = (axis.x * sinAngle);
	result.y = (axis.y * sinAngle);
	result.z = (axis.z * sinAngle);
	result.w = cos(angle);
	return result;
}

void QuaternionToAxisAngle(Quaternion quat, Vector * axis, float * angle)
{
	float sinAngle;
	
	QuaternionNormalize(&quat);
	sinAngle = sqrt(1.0f - (quat.w * quat.w));
	if (fabs(sinAngle) < 0.0005f) sinAngle = 1.0f;
	axis->x = (quat.x / sinAngle);
	axis->y = (quat.y / sinAngle);
	axis->z = (quat.z / sinAngle);
	*angle = (acos(quat.w) * 2.0f);
}

void QuaternionInvert(Quaternion * quat)
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

Quaternion QuaternionMultiply(Quaternion * quat1, Quaternion * quat2)
{
	Vector vector1, vector2, cross;
	Quaternion result;
	float angle;
	
	vector1.x = quat1->x;
	vector1.y = quat1->y;
	vector1.z = quat1->z;
	vector2.x = quat2->x;
	vector2.y = quat2->y;
	vector2.z = quat2->z;
	angle = ((quat1->w * quat2->w) - (VectorDot(vector1, vector2)));
	
	cross = VectorCross(vector1, vector2);
	vector1.x *= quat2->w;
	vector1.y *= quat2->w;
	vector1.z *= quat2->w;
	vector2.x *= quat1->w;
	vector2.y *= quat1->w;
	vector2.z *= quat1->w;
	
	result.x = (vector1.x + vector2.x + cross.x);
	result.y = (vector1.y + vector2.y + cross.y);
	result.z = (vector1.z + vector2.z + cross.z);
	result.w = angle;
	
	return result;
}

void QuaternionRotate(Quaternion * quat, Vector axis, float angle)
{
	Quaternion rotationQuat;
	
	rotationQuat = QuaternionFromAxisAngle(axis, angle);
	*quat = QuaternionMultiply(quat, &rotationQuat);
}

Vector QuaternionMultiplyVector(Quaternion * quat, Vector * vector)
{
	Quaternion vectorQuat, inverseQuat, resultQuat;
	Vector resultVector;
	
	vectorQuat.x = vector->x;
	vectorQuat.y = vector->y;
	vectorQuat.z = vector->z;
	vectorQuat.w = 0.0f;
	
	inverseQuat = *quat;
	QuaternionInvert(&inverseQuat);
	resultQuat = QuaternionMultiply(&vectorQuat, &inverseQuat);
	resultQuat = QuaternionMultiply(quat, &resultQuat);
	
	resultVector.x = resultQuat.x;
	resultVector.y = resultQuat.y;
	resultVector.z = resultQuat.z;
	
	return resultVector;
}

#pragma mark Kamera


struct __TRRawCam
{
	GLfloat defaultPosition[3];
	GLfloat translation[3];
	Quaternion rotation;
};


void camSetDefaultPosition(TRRawCam *cam, float x, float y, float z)
{
	if (!cam) return;
	cam->defaultPosition[0] = x;
	cam->defaultPosition[1] = y;
	cam->defaultPosition[2] = z;
}

void camReset(TRRawCam *cam)
{
	/*cam->translation[0] = cam->defaultPosition[0];
	cam->translation[1] = cam->defaultPosition[1];
	cam->translation[2] = cam->defaultPosition[2];*/
	cam->translation[0] = 0.0;
	cam->translation[1] = 0.0;
	cam->translation[2] = 0.0;
	cam->rotation.x = 0.0;
	cam->rotation.y = 0.0;
	cam->rotation.z = 0.0;
	cam->rotation.w = 1.0;
}

void camApplyTransformation(TRRawCam *cam, float *x, float *y, float *z, float *angleOut)
{
	float angle;
	Vector axis;
	
	QuaternionToAxisAngle(cam->rotation, &axis, &angle);
	
	angle = angle / (2 * M_PI);
	angle = angle * 360;
	
	glTranslatef(cam->translation[0], cam->translation[1], cam->translation[2]);
	glRotatef((GLfloat) angle, (GLfloat) axis.x, (GLfloat) axis.y, (GLfloat) axis.z);
	glTranslatef(cam->defaultPosition[0], cam->defaultPosition[1], cam->defaultPosition[2]);
	
	if (x != NULL) *x = axis.x;
	if (y != NULL) *y = axis.y;
	if (z != NULL) *z = axis.z;
	if (angleOut != NULL) *angleOut = angle;
}

void camMoveRelative(TRRawCam *cam, float x, float y, float z)
{
	/*Vector inVec = VectorCreate(x, y, z);
	Quaternion inverse = QuaternionCopy(cam->rotation);
	QuaternionInvert(&inverse);
	inVec = QuaternionMultiplyVector(&inverse, &inVec);
	cam->translation[0] += inVec.x;
	cam->translation[1] += inVec.y;
	cam->translation[2] += inVec.z;*/
	camMoveAbsolute(cam, x, y, z);
}

void camMoveAbsolute(TRRawCam *cam, float x, float y, float z)
{
	cam->translation[0] += x;
	cam->translation[1] += y;
	cam->translation[2] += z;
}

void camTurn(TRRawCam *cam, float aroundx, float aroundy, float aroundz)
{
	Quaternion turn;
	float sinX, sinY, sinZ;
	float cosX, cosY, cosZ;
	
	sinX = sinf(aroundx * 0.5);
	sinY = sinf(aroundy * 0.5);
	sinZ = sinf(aroundz * 0.5);
	
	cosX = cosf(aroundx * 0.5);
	cosY = cosf(aroundy * 0.5);
	cosZ = cosf(aroundz * 0.5);
	
	turn.x = sinX * cosY * cosZ + sinY * cosX * sinZ;
	turn.y = sinY * cosX * cosZ - sinX * cosY * sinZ;
	turn.z = sinX * sinY * cosZ + sinZ * cosX * cosY;
	turn.w = cosX * cosY * cosZ - sinX * sinY * sinZ;
	
/*	cam->rotation = QuaternionMultiply(&cam->rotation, &turn);	*/
	cam->rotation = QuaternionMultiply(&turn, &cam->rotation);
	
/*	cdata, dataIndexrintf(stderr, "Quaternion: h = %f + i * %f + j * %f + k * %f\n", cam->rotation.w, cam->rotation.x, cam->rotation.y, cam->rotation.z);
*/
}

TRRawCam *camCreate(void)
{
	TRRawCam *cam = malloc(sizeof(TRRawCam));
	cam->translation[0] = 0.0;
	cam->translation[1] = 0.0;
	cam->translation[2] = 0.0;
	cam->defaultPosition[0] = 0.0;
	cam->defaultPosition[1] = 0.0;
	cam->defaultPosition[2] = 0.0;
	Vector upvector = {0.0f, 1.0f, 0.0f};
	cam->rotation = QuaternionFromAxisAngle(upvector, 0.0f);
	return cam;
}
void camRelease(TRRawCam *cam)
{
	free(cam);
}