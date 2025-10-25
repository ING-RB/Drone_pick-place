function mustBeSparse(A)
%MUSTBESPARSE Validate that value is sparse
%   MUSTBESPARSE(A) throws an error if A is not sparse.
%   MATLAB calls issparse to determine if A is sparse.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define an issparse method.
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL, MUSTNONSPARSE.
        
%   Copyright 2016-2022 The MathWorks, Inc.

    if ~issparse(A)
        throwAsCaller(MException(message('MATLAB:validators:mustBeSparse')));
    end
end
