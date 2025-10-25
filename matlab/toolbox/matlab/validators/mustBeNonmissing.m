function mustBeNonmissing(A)
%MUSTBENONMISSING Validate that value is not missing
%   MUSTBENONMISSING(A) throws an error if A contains missing data.
%   MATLAB calls anymissing to determine if A contains missing data.
%
%   Class support:
%   All numeric classes, string
%   MATLAB classes that define these methods:
%       ismissing
%
%   See also: ISMISSING, ANYMISSING.

%   Copyright 2020-2021 The MathWorks, Inc.
if anymissing(A)
    throwAsCaller(MException(message('MATLAB:validators:mustBeNonmissing')));
end

% LocalWords:  ismissing validators anymissing
