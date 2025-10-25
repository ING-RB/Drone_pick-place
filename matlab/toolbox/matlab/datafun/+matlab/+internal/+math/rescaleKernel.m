function [R,C,S] = rescaleKernel(A,a,b,inputMin,inputMax)
% rescaleKernel Helper function for rescale and normalize
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2020 The MathWorks, Inc.

% Regularize constant values to return lowerbound of output range
constReg = (inputMin == inputMax);

% Determine where to center the problem based on the input range 
sigma = max(min(0,inputMax),inputMin);
inputMin = inputMin - sigma;
inputMax = inputMax - sigma;

% Scale to prevent overflow/underflow
e1 = nextpow2(max(abs(inputMax), abs(inputMin)));
r1 = 2.^(e1-1);
e2 = nextpow2(max(abs(a),abs(b)));
r2 = 2.^(e2-1);
r3 = 2.^(fix((e1+e2)/2)-1);

z = ((inputMax./r1).*(a./r3) - (inputMin./r1).*(b./r3) + (a./r3).*(constReg./r1)) ...
    ./ ((inputMax./r1)-(inputMin./r1) + (constReg./r1));
slope = ((b./r2)-(a./r2))./((inputMax./r3)-(inputMin./r3) + (constReg./r3));
if ~isfloat(A)
    R = r2 .* (slope./r3 .* (double(A) - sigma) + (r3./r2).*z);
else
    R = r2 .* (slope./r3 .* (A - sigma) + (r3./r2).*z);
end

% Check to make sure the output is within the output range
R = max(R, a, 'includenan');
R = min(R, b, 'includenan');

if nargout > 1
    C = sigma - ((r3./slope).*((r3.*z)./r2));
    S = r3./(slope.*r2);
end


