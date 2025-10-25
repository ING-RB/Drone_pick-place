function dz = dfresnelg2(x,dk,k,theta)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DFRESNELG2 Derivative of generalized Fresnel integral
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   DZ = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DFRESNELG2(L,DK,K,THETA)
%   returns the derivative with respect to length of the generalized
%   complex Fresnel integral:
%
%              /L
%              |
%        Z  =  |  exp(1i * ((DK/2)*s.^2 + K*s + THETA)) ds
%              |
%              /0
%    
%   evaluated over corresponding elements of L, DK, K, and THETA.  
%   L, DK, K and THETA must all have the same dimensions.


%#codegen

%   Copyright 2017-2020 The MathWorks, Inc.


dz = exp(1i.*(((dk./2).*x + k).*x+theta));


