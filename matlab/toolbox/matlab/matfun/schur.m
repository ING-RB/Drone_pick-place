function [U, T] = schur(X, flag)
%SCHUR  Schur decomposition.
%   [U,T] = SCHUR(X) produces a quasitriangular Schur matrix T and
%   a unitary matrix U so that X = U*T*U' and U'*U = EYE(SIZE(U)).
%   X must be square.
%
%   T = SCHUR(X) returns just the Schur matrix T.
%
%   If X is real, two different decompositions are available.
%   SCHUR(X,'real') has the real eigenvalues on the diagonal and the
%   complex eigenvalues in 2-by-2 blocks on the diagonal.
%   SCHUR(X,'complex') is triangular and is complex if X has complex
%   eigenvalues.  SCHUR(X,'real') is the default.
%
%   If X is complex, the complex Schur form is returned in matrix T.
%   The complex Schur form is upper triangular with the eigenvalues
%   of X on the diagonal. The second input is ignored in this case.
%
%   See RSF2CSF to convert from Real to Complex Schur form.
%
%   See also ORDSCHUR, QZ, RSF2CSF.

%   Copyright 1984-2022 The MathWorks, Inc.

if ~isfloat(X)
    error(message('MATLAB:schur:inputType'));
end

if ~allfinite(X)
    error(message('MATLAB:schur:matrixWithNaNInf'));
end
    
needTransform = false;
if nargin > 1
    if matlab.internal.math.partialMatch(flag, 'complex')
        needTransform = isreal(X);  % No transform needed if X is complex.
    elseif ~matlab.internal.math.partialMatch(flag, 'real')
        error(message('MATLAB:schur:unknownOption'));
    end
end

try
    if nargout < 2 && ~needTransform
        % Assume X has finite elements.
        U = matlab.internal.math.nofinitecheck.schur(X);
    else
        % Assume X has finite elements.
        [U, T] = matlab.internal.math.nofinitecheck.schur(X);
        if needTransform
            [U, T] = rsf2csf(U, T);
        end
        if nargout < 2
            U = T;
        end
    end
catch ME
    throw(ME)
end
