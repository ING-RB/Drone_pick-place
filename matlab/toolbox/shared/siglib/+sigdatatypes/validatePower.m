function x = validatePower(x,funcname,varname,varargin)
%VALIDATEPOWER Validate power values
%   validatePower(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid power. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validatePower(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.
%
%   Y = validatePower(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid power.
%       sigdatatypes.validatePower(30,'foo','bar');

%   Copyright 2009-2010 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

validateattributes(x,{'double'},{'finite','nonnan','nonempty',...
    'nonnegative'},funcname,varname);

if ~isempty(varargin)
    validateattributes(x,{'double'},varargin{:},funcname,varname);
end


% [EOF]
