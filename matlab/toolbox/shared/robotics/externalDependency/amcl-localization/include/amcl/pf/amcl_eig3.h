
/* Eigen-decomposition for symmetric 3x3 real matrices.
   Public domain, copied from the public domain Java library JAMA. */
   
/* 
 *  Copyright (C) 2015-2019 The MathWorks, Inc.
 *  MathWorks-specific modifications have been made to the original source. 
 *  These changes are permitted within the terms of the LGPL 2.1 license.
 */   

#ifndef AMCL_EIG3_H

/* Symmetric matrix A => eigenvectors in columns of V, corresponding
   eigenvalues in d. */
void eigen_decomposition(double A[3][3], double V[3][3], double d[3]);

#endif
