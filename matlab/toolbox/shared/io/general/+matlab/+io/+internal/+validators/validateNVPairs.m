function validateNVPairs(varargin)
%Common checks for name-value pair validitiy
% matlab.io.internal.validators.validateNVPairs(Name1,Value1,...)
%   will error if the number of arguments is odd--I.e. when there aren't
%   values for each of the names--and when any of the names are not
%   non-empty scalar text elements.
%
% See Also matlab.io.internal.validators.FunctionInterface,
%          matlab.io.internal.validators.struct2args

% Copyright 2018 The MathWorks, Inc.

if mod(nargin,2)~=0
    error(message('MATLAB:textio:textio:OddNumberNVPairs'));
end

for v = varargin(1:2:end)
    if ~isNonEmptyScalarText(v{1})
        error(message('MATLAB:InputParser:ParamMustBeChar'));
    end
end
end
        
function tf = isNonEmptyScalarText(v)
tf = ((isstring(v) && isscalar(v)) ...
   || (ischar(v) && isrow(v)))...
   && strlength(v) > 0 ;
end
