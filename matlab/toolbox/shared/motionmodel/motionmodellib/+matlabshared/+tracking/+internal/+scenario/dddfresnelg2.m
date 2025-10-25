function dddz = dddfresnelg2(x,dk,k,theta)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DDDFRESNELG2 Third derivative of generalized Fresnel integral
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   DDDZ = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DDDFRESNELG2(L,DK,K,THETA)
%   returns the third derivative with respect to length of the generalized
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

%    Copyright 2017-2020 The MathWorks, Inc.

%#codegen

dddz = exp(1i*(((dk/2).*x + k).*x+theta)).*((1i*dk) - (dk.*x+k).^2);


