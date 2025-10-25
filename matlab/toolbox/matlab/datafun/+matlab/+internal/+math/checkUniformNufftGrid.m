function tf = checkUniformNufftGrid(x)
%checkUniformNufftGrid  Checks if points are considered uniformly spaced
%for non-uniform FFT functions.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023 The MathWorks, Inc.
n = numel(x);
tf = (n < 2) || ((x(2) > x(1)) && isuniform(x));
if isscalar(x)
    tf = tf & isfinite(x);
elseif n == 2
    tf = tf & isfinite(x(2)-x(1));
end
end