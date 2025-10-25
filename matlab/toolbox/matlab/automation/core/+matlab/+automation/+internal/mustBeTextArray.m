function mustBeTextArray(value,varargin)
% This function is undocumented and may change in a future release.

%    mustBeTextArray(value) validates that the value provided is a string
%    array without missing elements, or a cell array of character vectors.
%
%    mustBeTextArray(...,nameOfValue) includes the nameOfValue
%    in any error thrown.

% Copyright 2022 The MathWorks, Inc.
import matlab.automation.internal.mustBeNonMissing;
validateattributes(value,{'string','cell'},{},'',varargin{:});
if iscell(value)
    if ~iscellstr(value)
        throwStringInputValidationError('NonCharCellArrayElement',varargin{:});
    end
else % isstring
    mustBeNonMissing(value,varargin{:});
end
end