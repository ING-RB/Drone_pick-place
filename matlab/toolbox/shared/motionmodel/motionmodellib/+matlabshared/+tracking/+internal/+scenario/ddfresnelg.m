function ddz = ddfresnelg(x,dk,k,theta)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DDFRESNELG Second derivative of generalized Fresnel integral
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   DDZ = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DDFRESNELG(L,DK,K,THETA)
%   returns the second derivative with respect to length of the
%   generalized complex Fresnel integral:
%
%              /L
%              |
%        Z  =  |  exp(1i * ((DK/2)*s.^2 + K*s + THETA)) ds
%              |
%              /0
%    
%   where DK, K, and THETA, are real scalar constants, and L is real
%   N-dimensional array of points over which to evaluate the integral.
%
%   If omitted, DK = pi, K = 0, THETA = 0.

%    Copyright 2017-2018 The MathWorks, Inc.

%#codegen

if nargin<2
    dk = pi;
end

if nargin<3
    k = 0;
end

if nargin<4
    theta = 0;
end


validateattributes(x,{'double'},{'real','finite'},'fresnelg','x',1);
validateattributes(dk,{'double'},{'real','scalar','finite'},'fresnelg','dk',2);
validateattributes(k,{'double'},{'real','scalar','finite'},'fresnelg','k',3);
validateattributes(theta,{'double'},{'real','scalar','finite'},'fresnelg','theta',4);

ddz = exp(1i*(((dk/2).*x + k).*x+theta)).*(1i*dk.*x+1i*k);


