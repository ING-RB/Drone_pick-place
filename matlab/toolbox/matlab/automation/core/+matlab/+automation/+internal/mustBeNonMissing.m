function mustBeNonMissing(value,varargin)
% This function is undocumented and may change in a future release.

%    mustBeNonMissing(value) validates that the value provided is does not
%    contain any missing values.
%
%    mustBeNonMissing(...,nameOfValue) includes the nameOfValue
%    in any error thrown.
%
%    Notes:
%       * If the value is a cell array, then no checking will be done. This
%         is prevent mustBeNonMissing({''}) from erroring since
%         ismissing({''}) returns true.
%       * If there is also a requirement that each element of value
%         contains more than one character, then use mustContainCharacters
%         instead since it also checks for missing values.

% Copyright 2022 The MathWorks, Inc.
if ~iscell(value) && any(reshape(ismissing(value),1,[]))
    if isscalar(value)
        throwStringInputValidationError('MustNotBeMissing',varargin{:});
    else
        throwStringInputValidationError('MustNotContainMissing',varargin{:});
    end
end
end