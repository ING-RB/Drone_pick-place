function x = validateArea(x,funcname,varname,varargin)
%VALIDATEAREA Validate area values
%   validateArea(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid area. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateArea(...,VARARGIN) specifies additional attributes supported in
%   VALIDATEATTRIBUTES, such as sizes and dimensions, in a cell array
%   VARARGIN.
%
%   Y = validateArea(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid area.
%       sigdatatypes.validateArea(30,'foo','bar');

%   Copyright 2009-2010 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

validateattributes(x,{'double'},{'nonnan','nonempty','nonnegative'},...
    funcname,varname);

if ~isempty(varargin)
validateattributes(x,{'double'},varargin{:},funcname,varname);
end


% [EOF]
