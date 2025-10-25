function mustBeFloat(A)
% MUSTBEFLOAT is for internal use only and may be removed or
% modified at any time

% MUSTBEFLOAT Validate that value is a floating-point array; otherwise issue an error
%   MUSTBEFLOAT(A) issues an error if A is not a floating-point array. The
%   floating-point types are single and double, and subclasses of single
%   and double.
%   MATLAB call isfloat(A) to determine if A is a float.
%
%   Class support:
%   All MATLAB classes
%
%   See also: isfloat
        
%   Copyright 2019-2020 The MathWorks, Inc.
    
    if ~isfloat(A)
        errorID = 'MATLAB:validators:mustBeFloat';
        E = MException(errorID, message(errorID).getString);
        throw(E);
    end
end

