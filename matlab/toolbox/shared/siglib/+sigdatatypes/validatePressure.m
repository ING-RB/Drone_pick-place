function x = validatePressure(x,funcname,varname,varargin)
%VALIDATEPRESSURE Validate pressure values
%   validatePressure(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid pressure value. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateDistance(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validateDistance(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid pressure value.
%       sigdatatypes.validatePressure(30,'foo','bar');

%   Copyright 2015 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

validateattributes(x,{'double'},{'nonnan','nonempty','nonnegative'},...
    funcname,varname);
if ~isempty(varargin)
    validateattributes(x,{'double'},varargin{:},funcname,varname);
end
% [EOF]
