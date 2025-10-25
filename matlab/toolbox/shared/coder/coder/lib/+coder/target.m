function y = target(targetIn)
%CODER.TARGET Determine the current code-generation target
%
%   CODER.TARGET('TARGET') determines if the specified TARGET is the
%   current code generation target. The following TARGET values may be
%   specified:
%       MATLAB      True if running in MATLAB (not generating code).
%       MEX         True if generating a MEX function.
%       Sfun        True if simulating a Simulink model.
%       Rtw         True if generating a LIB, DLL or EXE target.
%       HDL         True if generating an HDL target.
%       Custom      True if generating a custom target.
%
%   Example:
%       if coder.target('MATLAB')
%           % code for MATLAB evaluation
%       else
%           % code for code generation
%       end
%
%   See also coder.ceval.

%   Copyright 2006-2021 The MathWorks, Inc.

if nargin == 0
    % Backward compatibility
    y = '';
elseif ischar(targetIn) && size(targetIn,1) == 1 && size(targetIn, 2) == 6 &&...
        (targetIn(1) == 'M') && (targetIn(2) == 'A') && (targetIn(3) == 'T') &&...
        (targetIn(4) == 'L') && (targetIn(5) == 'A') && (targetIn(6) == 'B')
    % Fast path to optimize internal usage.
    y = true;
else
    y = ((ischar(targetIn) || (isstring(targetIn) && isscalar(targetIn))) ...
            && matches(targetIn, 'MATLAB', "IgnoreCase", true)) || isempty(targetIn);
end
