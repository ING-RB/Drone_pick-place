function x = getStateInfo(filt, funcname, arg1, arg2)
%   This function is for internal use only. It may be removed in the future. 
%GETSTATEINFO  Extract state info

%   Copyright 2021-2022 The MathWorks, Inc.


%#codegen 

    if nargin ==2 
        % getStateInfo(filt, 'stateinfo')
        x = filt.StateInfo;

    elseif nargin == 3
        % getStateInfo(filt, 'stateinfo', 'Position')
        si = filt.StateInfo;
        allf = fieldnames(si);
        coder.internal.assert(isStringScalar(arg1) || ischar(arg1), ...
            'insframework:insEKF:StateInfoStringInput');
        f = chkstring(filt, 1, arg1, allf, funcname, 3);
        x = si.(f);

    else % nargin == 4 
        % getStateInfo(filt, 'stateinfo', sensor, 'Bias')
        coder.internal.assert(isa(arg1, ...
            'positioning.INSSensorModel'), ...
            'insframework:insEKF:StateInfoSensorArg2');
        idx = getSensorIndex(filt, arg1);
        si = filt.SensorStateInfo{idx};
        allf = fieldnames(si);
        f = chkstring(filt, idx, arg2, allf, funcname, 4);
        x = si.(f);
    end
end


function f = chkstring(filt, idx, x, choices, funcname, narg)
% Check that a string is valid for stateinfo/stateparts/statecovparts.
% In codegen, just use validatestrings
% In MATLAB simulation, validatestrings can be slow, so cache known correct
% strings to avoid calls to validatestrings as much as possible.
%  Inputs
%       filt - handle to the filter
%       idx - if using the long form of stateinfo, the sensor index.
%               Ignored for short form. 
%       x  - string value to check
%       choices - possible valid choices of strings
%       funcname - name of function(stateinfo,stateparts,statecovparts) for
%           for throwing exceptions
%       narg - form of function call. 3 is short form, 4 is long form
%           e.g. 3 : getStateInfo(filt, 'stateinfo', 'Position')
%                4 : getStateInfo(filt, 'stateinfo', sensor, 'Bias')
%

if coder.target('MATLAB')
    % Nested try-catch. Inner try-catch checks if x is in the cache and
    % adds to the cache if it's not. This is faster than isKey in an
    % if-else.
    %
    % Outer try-catch throws if x is not a valid among choices.
    try 
        % Go to the cache first
        try
            if narg == 3
                f = filt.StatesCacheWithoutHandle(x);
            else
                f = filt.StatesCacheWithHandle{idx}(x);
            end
        catch % don't catch exception. Just fix it.
            f = validatestring(x, choices, funcname);
            if narg == 3
                filt.StatesCacheWithoutHandle(x) = f;
            else
                filt.StatesCacheWithHandle{idx}(x) = f;
            end
        end

    catch ME
        if strcmpi(ME.identifier, 'MATLAB:stateinfo:unrecognizedStringChoice') && narg == 4
            error(message('insframework:insEKF:StateInfoChoice', funcname, strjoin(choices, ', ')));
        else
            rethrow(ME);
        end
    end
else
    f = validatestring(x, choices, funcname);
end

end
