function x = validateFrequency(x,funcname,varname,varargin)
%VALIDATEFREQUENCY Validate frequency
%   validateFrequency(X,FUNC_NAME,VAR_NAME) validates whether the input X
%   represents valid frequency. FUNC_NAME and VAR_NAME are what used in
%   VALIDATEATTRIBUTES to come up error id and messages.
%
%   validateFrequency(...,VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions and datatypes, in a
%   cell array VARARGIN.
%
%   Y = validateFrequency(...) outputs the validated value.
%
%   Example:
%       % Validate whether 30 is a valid frequency value.
%       sigdatatypes.validateFrequency(30,'foo','bar');
%       % Validate whether single input is valid
%       sigdatatypes.validateFrequency(single(30),'foo','bar',{'double','single'},{'scalar'});

%   Copyright 2009-2018 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

if numel(varargin) < 2
    type = {'double'};
else
    type = varargin{1};
end
validateattributes(x,type,{'finite','nonempty',...
    'positive'},funcname,varname);

if ~isempty(varargin)
    
    if numel(varargin) < 2
        validateattributes(x,type,varargin{1},funcname,varname);
    else
        validateattributes(x,type,varargin{2},funcname,varname);
    end
end


% [EOF]
