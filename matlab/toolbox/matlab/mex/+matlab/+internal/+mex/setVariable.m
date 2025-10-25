function setVariable(varargin)
%    FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%    and is intended for use only with the scope of function in the MATLAB 
%    Engine APIs.  Its behavior may change, or the function itself may be 
%    removed in a future release.

% Copyright 2018 The MathWorks, Inc.

% SETVARIABLE set a MATLAB variable to the base or global workspace.
    varname = varargin{1};
    var = varargin{2};
    workspaceType = varargin{3};
    if strcmp(workspaceType, 'global')
        statement = ['global ' varname];
        %Rethrow the exception to generate MATLABExecutionException in C++ MEX
        try
            evalin('caller', statement);
        catch ex
            throw(ex)
        end
        assignin('caller', varname, var);
    else
        assignin('base', varname, var);
    end
end
