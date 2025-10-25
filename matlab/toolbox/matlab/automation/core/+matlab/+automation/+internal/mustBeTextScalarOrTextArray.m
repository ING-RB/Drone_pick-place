function mustBeTextScalarOrTextArray(value,varargin)
% This function is undocumented and may change in a future release.

%    mustBeTextScalarOrTextArray(value) validates that the value provided
%    is a character vector, a string array without missing elements, or a
%    cell array of character vectors.
%
%    mustBeTextScalarOrTextArray(...,nameOfValue) includes the nameOfValue
%    in any error thrown.

% Copyright 2022 The MathWorks, Inc.

import matlab.automation.internal.mustBeNonMissing;

validateattributes(value,{'char','string','cell'},{},'',varargin{:});
if iscell(value)
    if ~iscellstr(value)
        throwStringInputValidationError('NonCharCellArrayElement',varargin{:});
    end
elseif ischar(value)
    if ~isempty(value)
        validateattributes(value,{'char'},{'row'},'',varargin{:});
    end
else %isstring
    mustBeNonMissing(value,varargin{:});
end
end