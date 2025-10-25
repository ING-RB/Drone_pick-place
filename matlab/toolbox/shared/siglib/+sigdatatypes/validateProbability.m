function x = validateProbability(x, funcname, varname, varargin)
%VALIDATEPROBABILITY Validate probability value
%   validateProbability(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid probability values. FUNC_NAME and VAR_NAME are
%   used in VALIDATEATTRIBUTES to come up with the error id and message.
%
%   validateProbability(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions and datatypes, in a
%   cell array VARARGIN.
%
%   Y = validateProbability(...) outputs the validated value.
%
%   Example:
%       % Validate whether 0.5 is a valid probability value.
%       sigdatatypes.validateProbability(0.5,'foo','bar');
%       % Validate whether single input is valid
%       sigdatatypes.validateProbability(0.5,'foo','bar',{'double','single'},{'scalar'});

%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin) < 2
    type = {'double'};
else
    type = varargin{1};
end

validateattributes(x,type,{'finite','nonnan','nonempty',...
    '>=',0,'<=',1,'real'},funcname,varname);

if ~isempty(varargin)
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end


% [EOF]
