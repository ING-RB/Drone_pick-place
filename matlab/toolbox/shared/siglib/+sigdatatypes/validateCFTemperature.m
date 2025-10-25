function x = validateCFTemperature(x,funcname,varname,varargin)
%VALIDATEMPERATURE Validate temperature values
%   validateTemperature(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid temperature in Celsius or Fahreheit. FUNC_NAME and
%   VAR_NAME are used in VALIDATEATTRIBUTES to come up with the error id
%   and message.
%
%   validateTemperature(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validateTemperature(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid temperature in Celcius.
%       sigdatatypes.validateCFTemperature(30,'foo','bar',{'>=',-273.15});

%   Copyright 2015 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

validateattributes(x,{'double'},{'finite','nonempty','real'},funcname,varname);
if ~isempty(varargin)
    validateattributes(x,{'double'},varargin{:},funcname,varname);
end
% [EOF]
