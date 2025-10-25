function mustBeVector(A,allowEmpty)
%MUSTBEVECTOR Validate that value is a 1-by-n or n-by-1 vector
%   MUSTBEVECTOR(A) throws an error if A is not a vector.
%   MATLAB calls isvector to determine if A is a vector.
%
%   MUSTBEVECTOR(A,'allow-all-empties') throws an error if A is neither a
%   vector nor any empty array.
%
%   Class support:
%   All MATLAB classes
%
%   See also: ISVECTOR.

%   Copyright 2020-2021 The MathWorks, Inc.

if nargin == 2
    if ((ischar(allowEmpty) && isrow(allowEmpty)) || ...
            (isstring(allowEmpty) && isscalar(allowEmpty) && strlength(allowEmpty)>0)) && ...
            startsWith("allow-all-empties",allowEmpty,"IgnoreCase",true)
        if isempty(A)
            return;
        end
    else
        error(message('MATLAB:validatorUsage:invalidSecondInput','mustBeVector','allow-all-empties'));
    end
end

if ~isvector(A)
    throwAsCaller(MException(message('MATLAB:validators:mustBeVector')));
end
