function mustContainCharacters(value,varargin)
% This function is undocumented and may change in a future release.

%    mustContainCharacters(value) validates that each element of the value
%    has at least one character.
%
%    mustContainCharacters(...,nameOfValue) includes the nameOfValue in any
%    error thrown.

% Copyright 2017-2022 The MathWorks, Inc.
if ~all(reshape(strlength(value) > 0,1,[])) % also handles the string(missing) cases
    if ischar(value) || isscalar(value)
        throwStringInputValidationError('MustContainCharacters',varargin{:});
    else
        throwStringInputValidationError('EachMustContainCharacters',varargin{:});
    end
end
end