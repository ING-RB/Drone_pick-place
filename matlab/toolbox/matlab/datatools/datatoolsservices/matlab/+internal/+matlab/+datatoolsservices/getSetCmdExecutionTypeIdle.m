% This class is unsupported and might change or be removed without
% notice in a future version.

% getSetCmdExecutionTypeIdle can be used to change how commands run through
% executeCmd are dequeued.  By default, they will dequeue when the Matlab prompt
% is displayed, but this function can be used to force it to dequeue when Matlab
% is idle.  Note that Matlab idle can be at any pause, so is not guaranteed to
% be at the user's workspace.

% Copyright 2019-2020 The MathWorks, Inc.

function t = getSetCmdExecutionTypeIdle(varargin)
    mlock();
    persistent forceIdle;
    if isempty(forceIdle)
        forceIdle = false;
    end
    
    if nargin == 0
        t = forceIdle;
    else
        if islogical(varargin{1})
            forceIdle = varargin{1};
        end
        t = [];
    end
end