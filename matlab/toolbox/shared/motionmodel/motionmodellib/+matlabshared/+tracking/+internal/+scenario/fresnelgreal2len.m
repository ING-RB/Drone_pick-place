function len = fresnelgreal2len(x,dk,k,theta)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELGREAL2LEN lookup length along real axis
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   L = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELREAL2LEN(X, DK, K, THETA)
%   returns the closest length, L, on the generalized Fresnel curve:
%
%          /L
%          |
%      Z = |  exp(1i * ((DK/2)*s.^2 + K*s + THETA)) ds
%          |
%          /0
%   
%   such that real(Z) = x.

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

validateattributes(x,{'double'},{'real','vector','finite'},'fresnelgreal2len','x',1);
validateattributes(dk,{'double'},{'real','scalar','finite'},'fresnelgreal2len','dk',2);
validateattributes(k,{'double'},{'real','scalar','finite'},'fresnelgreal2len','k',3);
validateattributes(theta,{'double'},{'real','scalar','finite'},'fresnelgreal2len','theta',4);

% initial guess
len = initializeGuess(x,dk,k,theta);

% bail after 20 newton-raphson iterations
maxiter = 20;

z = matlabshared.tracking.internal.scenario.fresnelg(len,dk,k,theta);
dx = real(z)-x;
oldVal = Inf(size(dx));

iter = 0;
while any(abs(dx) < oldVal) && iter < maxiter
    oldVal = abs(dx);
    dzdl = matlabshared.tracking.internal.scenario.dfresnelg(len,dk,k,theta);

    len = len - dx ./ real(dzdl);
    z = matlabshared.tracking.internal.scenario.fresnelg(len,dk,k,theta);
    dx = real(z)-x;
    iter = iter + 1;
end

% did we fail?
len(abs(dx)>1e-2) = nan;


function len = initializeGuess(x,dk,k,theta)

% construct a ramp where we believe the central curve to exist
[l0, l1] = inflections(dk,k,theta);

len0 = linspace(l0,l1,1000);

% compute test values along row
z0 = matlabshared.tracking.internal.scenario.fresnelg(len0(:)',dk,k,theta);

% compute difference of estimate along each column
xtest = abs(bsxfun(@minus,real(z0),x(:)));

% for codegen
if isscalar(xtest)
  i=1;
else
  [~,i] = min(xtest,[],2);
end

% fetch best result
tempLen = len0(i);

% clamp values beyond computed limits if not nearly linear
if l0~=0 && l1~=0
    xmin = real(matlabshared.tracking.internal.scenario.fresnelg(l0,dk,k,theta));
    xmax = real(matlabshared.tracking.internal.scenario.fresnelg(l1,dk,k,theta));
    tempLen(x<xmin) = NaN;
    tempLen(x>xmax) = NaN;
end

len = zeros(size(x));
len(:) = tempLen(:);

function [l0,l1] = inflections(dk,k,theta)
% compute the closest inflection points towards the origin.
% To find the points, we find the lengths along the curve
% where the tangent of the imaginary part of the curve tangent is zero.
%   i.e. imag(dfresnelg([l0 l1], dk, k, theta) == 0.
%   which is equivalent to solving dk/2*l^2 + k*l + theta = +/- pi/2.

l = nan(1,4);
if k^2-2*dk*(theta+pi/2)>=0
  l(1) = (-k+sqrt(k^2-2*dk*(theta+pi/2)))/dk;
  l(2) = (-k-sqrt(k^2-2*dk*(theta+pi/2)))/dk;
end
if k^2-2*dk*(theta-pi/2)>=0
  l(3) = (-k+sqrt(k^2-2*dk*(theta-pi/2)))/dk;
  l(4) = (-k-sqrt(k^2-2*dk*(theta-pi/2)))/dk;
end
if abs(dk)<1e-9
  l(1) = ( pi/2 - theta)/k;
  l(2) = (-pi/2 - theta)/k;
  l(3) = ( pi/2-2*pi - theta)/k;
  l(4) = (-pi/2+2*pi - theta)/k;
  % if nearly linear, just report zero for inflections
  % newton-raphson converges quickly for linear.
  if abs(k)<1e-9
      l(1:4) = 0;
  end
end

if any(l>0) && any(l<0)
  % prefer returning the length of curve that straddles the origin.
  l0 = max(l(l<0));
  l1 = min(l(l>0));
else
  l0 = max(l);
  l1 = min(l);
end

