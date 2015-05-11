/*
 *  TRRawViewCam.h
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

typedef struct __TRRawCam TRRawCam;

void camSetDefaultPosition(TRRawCam *cam, float x, float y, float z);

void camReset(TRRawCam *cam);

void camApplyTransformation(TRRawCam *cam, float *x, float *y, float *z, float *angle);

void camMoveRelative(TRRawCam *cam, float x, float y, float z);

void camMoveAbsolute(TRRawCam *cam, float x, float y, float z);

void camTurn(TRRawCam *cam, float aroundx, float aroundy, float aroundz);

TRRawCam *camCreate(void);
void camRelease(TRRawCam *cam);