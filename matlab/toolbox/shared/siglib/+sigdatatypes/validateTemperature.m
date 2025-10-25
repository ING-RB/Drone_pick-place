function x = validateTemperature(x,funcname,varname,varargin)
%VALIDATEMPERATURE Validate temperature values
%   validateTemperature(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid temperature in Kelvin. FUNC_NAME and VAR_NAME are used
%   in VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateTemperature(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validateTemperature(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid temperature in Kelvin.
%       sigdatatypes.validateTemperature(30,'foo','bar');

%   Copyright 2009-2015 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

validateattributes(x,{'double'},{'finite','nonempty','nonnegative'},funcname,varname);
if ~isempty(varargin)
    validateattributes(x,{'double'},varargin{:},funcname,varname);
end
% [EOF]
