function x = validateIndex(x,funcname,varname,varargin)
%VALIDATEINDEX Validate index value
%   validateIndex(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid index values. FUNC_NAME and VAR_NAME are used in
%   VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateIndex(...,VARARGIN) specifies additional attributes supported
%   in VALIDATEATTRIBUTES, such as sizes and dimensions and datatypes, in a cell array
%   VARARGIN.
%
%   Y = validateIndex(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid index value.
%       sigdatatypes.validateIndex(30,'foo','bar');
%       % Validate whether single input is valid
%       sigdatatypes.validateIndex(single(30),'foo','bar',{'double','single'},{'positive'});

%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>
if numel(varargin) < 2
    type = {'double'} ;
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty',...
    'positive','integer'},funcname,varname);

if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end

%targetEcho

% [EOF]
