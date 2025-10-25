function dpp = derivpp(pp)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DERIVPP Derivative of piecewise polynomial.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   DPP = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DERIVPP(PP) returns the
%   derivative of the piecewise polynomial, PP.  PP is a piecewise
%   polynomial created by piecewise polynomial utilities, (e.g. MKPP or
%   SPLINE)
%
%    This function only supports 4th order polynomials because of code
%    generation constraints.
%
%   SEE ALSO MKPP, UNMKPP, SPLINE, PCHIP.

%  Copyright 2017-2018 The MathWorks, Inc.

%#codegen

order = coder.const(4);
dim = coder.const(1);

% extract the coefficients
[breaks,coefs,npieces] = unmkpp(pp);

% take the derivative of each polynomial
newCoefs = reshape(coefs(:), npieces, order);
newCoefs = repmat([0, order-1:-1:1],dim*npieces,1).*circshift(newCoefs, 1, 2);
dpp = mkpp(breaks,newCoefs,dim);
