function pauseHelper(varargin)
%MATLAB Code Generation Private function

%   Copyright 2019 The MathWorks, Inc.

% Helper to be called extrinsically for pause. This function is only invoked from the codegen pause
% when extrinsic calls are disabled and pause('query') returns 'on'.

narginchk(0,1);

% Force MATLAB pause to be enabled and set up to restore the state.
pauseState = pause('on');
c = onCleanup(@()pause(pauseState));
pause(varargin{:});
