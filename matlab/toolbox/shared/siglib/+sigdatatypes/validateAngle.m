function x = validateAngle(x,funcname,varname,varargin)
%VALIDATEANGLE Validate angle values
%   validateAngle(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid angles. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateAngle(...,VARARGIN) specifies additional attributes supported
%   in VALIDATEATTRIBUTES, such as sizes and dimensions and datatypes, in a cell array
%   VARARGIN.
%
%   Y = validateAngle(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid angle value.
%       sigdatatypes.validateAngle(30,'foo','bar');
%       % Validate whether single input is a valid angle value.
%       sigdatatypes.validateAngle(single(30),'foo','bar',{'double','single'},{'row'});

%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin) < 2
    type = {'double'} ;
else
    type = varargin{1};
end
validateattributes(x,type,{'finite','nonnan','nonempty','real'},...
    funcname,varname);

if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end



% [EOF]
