function [zcp,x,d] = fresnelgcp(z,dk,k,theta,x0)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELGCP Closest point on generalized clothoid
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [Zcp,L] = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELGCP(Z, DK, K, THETA)
%   returns the closest point, Zcp, on the generalized Fresnel curve:
%
%          /L
%          |
%          |  exp(1i * ((DK/2)*s.^2 + K*s + THETA)) ds
%          |
%          /0
%   
%   closest to the point Z. It additionally returns the integration limit L,
%   corresponding to the point Zcp.  
%
%   [...] = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELGCP(Z, DK, K, THETA, L0)
%   provides a vector of initial estimates for the integration limit L.  If supplied,
%   L is initialized to point with the smallest distance to Z and a Newton-Raphson
%   iteration is performed to find L.  The default value is zero.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

validateattributes(z,{'double'},{'vector','finite'},'fresnelg','z',1);
validateattributes(dk,{'double'},{'real','scalar','finite'},'fresnelg','dk',2);
validateattributes(k,{'double'},{'real','scalar','finite'},'fresnelg','k',3);
validateattributes(theta,{'double'},{'real','scalar','finite'},'fresnelg','theta',4);

% provide a hint to MATLAB Coder that these input parameters are scalars.
% without this hitn we encounter a size mismatch error when implicit
% expansion is enabled (see g2379676).
dk1 = dk(1);
k1 = k(1);
theta1 = theta(1);

if nargin<5
    [zcp,x,d] = fresnelgcp_impl(z,dk1,k1,theta1);
else
    [zcp,x,d] = fresnelgcp_impl(z,dk1,k1,theta1,x0);
end

%%%%%%%%

function [zcp,x,d] = fresnelgcp_impl(z,dk,k,theta,x0)

if nargin<5
    x = zeros(size(z));
else
    validateattributes(x0,{'double'},{'real','vector','finite'},'fresnelg','x',5);
    x = initializeGuess(z,dk,k,theta,x0);
end

zcp = matlabshared.tracking.internal.scenario.fresnelg(x,dk,k,theta);
zd = zcp-z;

numIter = 20;

for iter=1:numIter
    
    dzdx = zd .* conj(matlabshared.tracking.internal.scenario.dfresnelg(x,dk,k,theta));
    ddzdxx = 1 - dzdx .* 1i .* (dk.*x+k);

    x = x - real(dzdx) ./ real(ddzdxx);
    zcp = matlabshared.tracking.internal.scenario.fresnelg(x,dk,k,theta);
    zd = zcp-z;
end

d = abs(zd);



function x = initializeGuess(z,dk,k,theta,x0)

% compute test values along row
zcp0 = matlabshared.tracking.internal.scenario.fresnelg(x0(:)',dk,k,theta);

% compute difference of estimate along each column
ztest = abs(bsxfun(@minus,zcp0,z(:)));

% for codegen
if isscalar(ztest)
  i=1;
else
  [~,i] = min(ztest,[],2);
end

% fetch best result
x = x0(i);
