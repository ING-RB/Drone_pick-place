function mustBeComplex(A)
%MUSTBECOMPLEX Validate that value is complex
%   MUSTBECOMPLEX(A) throws an error if A contains real values. 
%   MATLAB call isreal to determine if A is complex.
%
%   Class support:
%   All MATLAB classes
%
%   See also: ISREAL.
        
%   Copyright 2021 The MathWorks, Inc.
    
    if isreal(A)
        throwAsCaller(MException(message('MATLAB:validators:mustBeComplex')));
    end
end
