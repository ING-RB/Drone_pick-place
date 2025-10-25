function x = validateSpeed(x,funcname,varname,varargin)
%VALIDATESPEED Validate speed
%   validateSpeed(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid speed values. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateSpeed(...,VARARGIN) specifies additional attributes supported
%   in VALIDATEATTRIBUTES, such as sizes and dimensions and datatypes, in a cell array
%   VARARGIN.
%
%   Y = validateSpeed(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid speed value.
%       sigdatatypes.validateSpeed(30,'foo','bar');
%       % Validate whether single input is valid 
%       sigdatatypes.validateSpeed(single(30),'foo','bar',{'double','single'},{'scalar'});

%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin)< 2
    type = {'double'};
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty'...
    'nonnegative'},funcname,varname);

cond = any(x>3e8);
if cond
    coder.internal.errorIf(cond,'siglib:sigdatatypes:schema:expectSlowerThanLight',varname);
end

if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end

% [EOF]
