function C = conv2(varargin)
%CONV2 Two dimensional convolution for tall arrays
%   C = CONV2(A, B)
%   C = CONV2(H1, H2, A)
%   C = CONV2(..., SHAPE)
%
%   Limitations:
%   1) A and B must not be empty if SHAPE is "full" (default).
%   2) When SHAPE is "full" (default) only one of A, B can be a tall array.
%   3) When SHAPE is "same" or "valid" B cannot be a tall array.
%   4) H1 and H2 cannot be tall arrays.
%
%   See also CONV2, TALL.

%   Copyright 2017-2019 The MathWorks, Inc.

narginchk(2,4);
shape = 'full';
separable = false;
switch nargin
    case 2
        [A,B,shape] = iCheckNonSeparableInputs(varargin{:}, shape);
    case 3
        if matlab.internal.datatypes.isScalarText(varargin{3}) ...
                || any(tall.getClass(varargin{3}) == ["char", "string"])
            [A,B,shape] = iCheckNonSeparableInputs(varargin{:});
        else
            % No trailing string flag, so must be separable form
            [H1,H2,A] = iCheckSeparableInputs(varargin{:});
            separable = true;
        end
    case 4
        [H1,H2,A] = iCheckSeparableInputs(varargin{1:3});
        shape = varargin{4};
        tall.checkNotTall(upper(mfilename), 3, shape);
        separable = true;
end

try
    shape = validatestring(shape, {'full', 'same', 'valid'});
catch
    error(message('MATLAB:conv2:unknownShapeParameter'));
end

% Whichever form is used, A must be tall and B (or H1, H2) must not be.
if separable
    kernel = {H1, H2};
else
    kernel = {B};
end

% Call shared implementation
C = convImpl(shape, A, kernel{:});

end

function [A,B,shape] = iCheckNonSeparableInputs(A,B,shape)
% Helper to check non-separable inputs
try
    % Two input form. Only one can be tall.
    if istall(A) && istall(B)
        error(message("MATLAB:bigdata:array:ConvBothTall", upper(mfilename)));
    end
    tall.checkNotTall(upper(mfilename), 2, shape);

    allowedTypes = {'numeric', 'logical'};
    A = tall.validateNotSparse(A, "MATLAB:conv2:SparseInput");
    A = tall.validateMatrix(A, "MATLAB:conv2:ndArrayInput");
    A = tall.validateTypeWithError(A, 'conv2', 1, allowedTypes, "MATLAB:conv2:inputType");

    B = tall.validateNotSparse(B, "MATLAB:conv2:SparseInput");
    B = tall.validateMatrix(B, "MATLAB:conv2:ndArrayInput");
    B = tall.validateTypeWithError(B, 'conv2', 2, allowedTypes, "MATLAB:conv2:inputType");
    
    if matlab.internal.datatypes.isScalarText(shape) && shape == "full"
        % "full" conv2(A,B) == conv2(B,A) so we don't care which is tall,
        % but for simplicity in the shared code, make sure A is the tall
        % one.
        if istall(B)
            [A,B] = deal(B,A);
        end
    else
        % For "same" and "valid" only A is allowed to be tall
        tall.checkIsTall(upper(mfilename), 1, A);
        tall.checkNotTall(upper(mfilename), 1, B);
    end    
catch err
    throwAsCaller(err);
end
end

function [H1,H2,A] = iCheckSeparableInputs(H1,H2,A)
% Helper to check separable inputs
try
    tall.checkIsTall(upper(mfilename), 3, A);
    tall.checkNotTall(upper(mfilename), 0, H1, H2);
    A = tall.validateMatrix(A, 'MATLAB:conv2:ndArrayInput');
    % First check that H1 and H2 are not N-D arrays, then check they are
    % not sparse.
    if ~(ismatrix(H1) && ismatrix(H2))
        error(message('MATLAB:conv2:ndArrayInput'));
    elseif issparse(H1) || issparse(H2)
        error(message('MATLAB:conv2:SparseInput'));
    end
    allowedTypes = {'numeric', 'logical'};
    typeErr = 'MATLAB:conv2:inputTypeSeparable';
    A = tall.validateTypeWithError(A, 'conv2', 3, allowedTypes, typeErr);
    H1 = tall.validateTypeWithError(H1, 'conv2', 1, allowedTypes, typeErr);
    H2 = tall.validateTypeWithError(H2, 'conv2', 2, allowedTypes, typeErr);
    H1 = tall.validateVectorOrEmpty(H1, 'MATLAB:conv2:firstTwoInputsNotVectors');
    H2 = tall.validateVectorOrEmpty(H2, 'MATLAB:conv2:firstTwoInputsNotVectors');
catch err
    throwAsCaller(err);
end
end
