function a = removevars(a,vars)
%

%   Copyright 2017-2024 The MathWorks, Inc.

% Avoid unsharing of shared-data copy across function call boundary
import matlab.lang.internal.move

if nargin < 2
    vars = [];
end
% creating = false, removing = true
a(:,vars) = [];
