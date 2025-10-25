function C = convn(A, B, shape)
%CONVN N-dimensional convolution for tall arrays
%   C = CONVN(A, B)
%   C = CONVN(A, B, SHAPE)
%
%   Limitations:
%   1) A must not be empty if SHAPE is 'full' (default).
%   2) When SHAPE is "full" (default) only one of A, B can be a tall array.
%   3) When SHAPE is "same" or "valid" B cannot be a tall array.
%
%   See also CONVN, TALL.

%   Copyright 2017-2019 The MathWorks, Inc.

narginchk(2,3);
if nargin<3
    shape = 'full';
else
    % SHAPE must not be tall and must be 'full', 'same', or 'valid'.
    tall.checkNotTall(upper(mfilename), 2, shape);
    try
        shape = validatestring(shape, {'full', 'same', 'valid'});
    catch
        error(message('MATLAB:convnc:UnsupportedDataType'));
    end   
end

% Check for sparse
A = tall.validateNotSparse(A, "MATLAB:convnc:SparseInput");
B = tall.validateNotSparse(B, "MATLAB:convnc:SparseInput");
% Check input types - throws same as standard CONV
allowedTypes = {'numeric', 'logical'};
A = tall.validateTypeWithError(A, 'convn', 1, allowedTypes, "MATLAB:convnc:inputType");
B = tall.validateTypeWithError(B, 'convn', 2, allowedTypes, "MATLAB:convnc:inputType");

if shape == "full"
    % Limitation 2: For "full" either one can be tall but not both
    if istall(A) && istall(B)
        error(message("MATLAB:bigdata:array:ConvBothTall", upper(mfilename)));
    end
    % To keep things simple in the shared code, make sure A is the tall
    % input and B the in-memory input.
    if istall(B)
        [A,B] = deal(B,A);
    end
else
    % Limitation 3: For "same", "valid", A must be tall, B must be in-memory
    tall.checkIsTall(upper(mfilename), 1, A);
    tall.checkNotTall(upper(mfilename), 1, B);
end

C = convImpl(shape, A, B);

end
