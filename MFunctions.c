/*
 *  MMath.c
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

#include "MFunctions.h"
#include <OpenGL/gl.h>

MSphere MSphereUnion(MSphere a, MSphere b)
{
	MVec3 vector = MVecSub(a.center, b.center);
	float distance = MVecLength(vector);
	
	if ((distance + b.radius) < a.radius) return a;
	if ((distance + a.radius) < b.radius) return b;
	
	MSphere result;
	result.radius = 0.5f * (distance + a.radius + b.radius);
	vector = MVecScale(vector, 1.0f / distance);
	
	result.center = MVecAdd(b.center, MVecScale(vector, (a.radius + distance - b.radius) * 0.5f));
	return result;
}

MSphere MSpheresUnion(MSphere spheres[], unsigned sphereCount)
{
	unsigned i;
	MSphere result = MSphereUnion(spheres[0], spheres[1]);
	if (sphereCount < 3) return result;
	
	for (i = 2; i < sphereCount; i++)
		result = MSphereUnion(spheres[i], result);
	
	return result;
}

int MVertexCloudWithinPlanes(MVec3 box[], unsigned vertexCount, MPlane planes[], unsigned planeCount)
{
	#ifdef __OBJC__
	NSLog(@"MVertexCloudWithinPlanes(%p, %u, %p, %u);", box, vertexCount, planes, planeCount);
	#endif
	int incount = 0; // Zählt, wie viele Ebenen alle Punkte auf der richtigen Seite haben
	int i, j;
	for (i = 0; i < planeCount; ++i)
	{
		int planeIn = vertexCount; // Zählt, wie viele der Punkte auf der richtigen Seite der Ebene liegen
		for (j = 0; j < vertexCount; ++j)
		{
			float multResult = MPlaneVecMultiply(planes[i], box[j]);
			if (multResult < 0.0f)
				planeIn -= 1;
		}
		
		if (planeIn == 0) return -1;
		if (planeIn == vertexCount) incount += 1;
	}
	
	if (incount == planeCount) return 1;
	else return 0;
}

void MGetOpenGLViewFrustum(MPlane outPlanes[6])
{
	MMatrix projectionMatrix = MMatrixIdentity();
	glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix.direct);
	MGetOpenGLViewFrustumStoredProjectionMatrix(outPlanes, projectionMatrix);
}

void MGetOpenGLViewFrustumStoredProjectionMatrix(MPlane planes[6], MMatrix projectionMatrix)
{
	MMatrix modelviewMatrix = MMatrixIdentity();
	glGetFloatv(GL_MODELVIEW_MATRIX, modelviewMatrix.direct);
	MMatrix cMatrix = MMatrixMultiply(modelviewMatrix, projectionMatrix);
	
	// Near plane
	planes[0].normal.x = cMatrix.direct[3] + cMatrix.direct[2];
	planes[0].normal.y = cMatrix.direct[7] + cMatrix.direct[6];
	planes[0].normal.z = cMatrix.direct[11] + cMatrix.direct[10];
	planes[0].d = cMatrix.direct[15] + cMatrix.direct[14];
	// Far plane
	planes[1].normal.x = cMatrix.direct[3] - cMatrix.direct[2];
	planes[1].normal.y = cMatrix.direct[7] - cMatrix.direct[6];
	planes[1].normal.z = cMatrix.direct[11] - cMatrix.direct[10];
	planes[1].d = cMatrix.direct[15] - cMatrix.direct[14];
	// Left plane
	planes[2].normal.x = cMatrix.direct[3] + cMatrix.direct[0];
	planes[2].normal.y = cMatrix.direct[7] + cMatrix.direct[4];
	planes[2].normal.z = cMatrix.direct[11] + cMatrix.direct[8];
	planes[2].d = cMatrix.direct[15] + cMatrix.direct[12];
	// Right plane
	planes[3].normal.x = cMatrix.direct[3] - cMatrix.direct[0];
	planes[3].normal.y = cMatrix.direct[7] - cMatrix.direct[4];
	planes[3].normal.z = cMatrix.direct[11] - cMatrix.direct[8];
	planes[3].d = cMatrix.direct[15] - cMatrix.direct[12];
	// Bottom plane
	planes[4].normal.x = cMatrix.direct[3] + cMatrix.direct[1];
	planes[4].normal.y = cMatrix.direct[7] + cMatrix.direct[5];
	planes[4].normal.z = cMatrix.direct[11] + cMatrix.direct[9];
	planes[4].d = cMatrix.direct[15] + cMatrix.direct[13];
	// Top plane
	planes[5].normal.x = cMatrix.direct[3] - cMatrix.direct[1];
	planes[5].normal.y = cMatrix.direct[7] - cMatrix.direct[5];
	planes[5].normal.z = cMatrix.direct[11] - cMatrix.direct[9];
	planes[5].d = cMatrix.direct[15] - cMatrix.direct[13];
	
	MPlaneNormalize(&planes[0]);
	MPlaneNormalize(&planes[1]);
	MPlaneNormalize(&planes[2]);
	MPlaneNormalize(&planes[3]);
	MPlaneNormalize(&planes[4]);
	MPlaneNormalize(&planes[5]);
}