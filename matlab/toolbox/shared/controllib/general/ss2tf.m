function [num, den] = ss2tf(varargin)
%SS2TF  State-space to transfer function conversion.
%   [NUM,DEN] = SS2TF(A,B,C,D,iu)  calculates the transfer function:
%
%               NUM(s)          -1
%       H(s) = -------- = C(sI-A) B + D
%               DEN(s)
%   of the system:
%       .
%       x = Ax + Bu
%       y = Cx + Du
%
%   from the iu'th input.  Vector DEN contains the coefficients of the
%   denominator in descending powers of s.  The numerator coefficients
%   are returned in matrix NUM with as many rows as there are 
%   outputs y.
%
%   See also TF2SS, ZP2TF, ZP2SS.

%   Copyright 1984-2011 The MathWorks, Inc.

% Compute poles and zeros
try
   [z,p,k] = ss2zp(varargin{:});
catch ME
   throw(ME)
end

% Build denominator
den = poly(p);

% Build numerator(s)
[ny,nu] = size(k);
if nu==0  % legacy
   num = zeros(ny,0);
else
   lden = numel(den);
   num = zeros(ny,lden);
   for j=1:ny
      zj = z(:,j);
      zj = zj(isfinite(zj));
      num(j,lden-numel(zj):lden) = k(j) * poly(zj);
   end
end
