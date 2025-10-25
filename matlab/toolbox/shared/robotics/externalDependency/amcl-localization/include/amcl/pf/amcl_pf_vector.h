/*
 *  Player - One Hell of a Robot Server
 *  Copyright (C) 2000  Brian Gerkey   &  Kasper Stoy
 *                      gerkey@usc.edu    kaspers@robotics.usc.edu
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */
/**************************************************************************
 * Desc: Vector functions
 * Author: Andrew Howard
 * Date: 10 Dec 2002
 * CVS: $Id: pf_vector.h 6345 2008-04-17 01:36:39Z gerkey $
 *************************************************************************/
 
/* 
 *  Copyright (C) 2015-2019 The MathWorks, Inc.
 *  MathWorks-specific modifications have been made to the original source. 
 *  These changes are permitted within the terms of the LGPL 2.1 license.
 */

#ifndef AMCL_PF_VECTOR_H
#define AMCL_PF_VECTOR_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

#ifdef BUILDING_3P_AMCL
#include "../amcl/amcl_exports.h"
#else
#include "amcl_exports.h"
#endif
  
// The basic vector
typedef struct
{
  double v[3];
} pf_vector_t;


// The basic matrix
typedef struct
{
  double m[3][3];
} pf_matrix_t;


// Return a zero vector
LIBRARY_API pf_vector_t pf_vector_zero();

// Check for NAN or INF in any component
LIBRARY_API int pf_vector_finite(pf_vector_t a);

// Print a vector
LIBRARY_API void pf_vector_fprintf(pf_vector_t s, FILE *file, const char *fmt);

// Simple vector addition
LIBRARY_API pf_vector_t pf_vector_add(pf_vector_t a, pf_vector_t b);

// Simple vector subtraction
LIBRARY_API pf_vector_t pf_vector_sub(pf_vector_t a, pf_vector_t b);

// Transform from local to global coords (a + b)
LIBRARY_API pf_vector_t pf_vector_coord_add(pf_vector_t a, pf_vector_t b);

// Transform from global to local coords (a - b)
LIBRARY_API pf_vector_t pf_vector_coord_sub(pf_vector_t a, pf_vector_t b);


// Return a zero matrix
LIBRARY_API pf_matrix_t pf_matrix_zero();

// Check for NAN or INF in any component
LIBRARY_API int pf_matrix_finite(pf_matrix_t a);

// Print a matrix
LIBRARY_API void pf_matrix_fprintf(pf_matrix_t s, FILE *file, const char *fmt);

// Compute the matrix inverse.  Will also return the determinant,
// which should be checked for underflow (indicated singular matrix).
//pf_matrix_t pf_matrix_inverse(pf_matrix_t a, double *det);

// Decompose a covariance matrix [a] into a rotation matrix [r] and a
// diagonal matrix [d] such that a = r * d * r^T.
LIBRARY_API void pf_matrix_unitary(pf_matrix_t *r, pf_matrix_t *d, pf_matrix_t a);

#ifdef __cplusplus
}
#endif

#endif
