function C = conv(A, B, shape)
%CONV Convolution and polynomial multiplication for tall arrays
%   C = CONV(A,B)
%   C = CONV(A,B,SHAPE)
%
%   Limitations:
%   1) A and B must both be column vectors.
%   2) When SHAPE is "full" (default) only one of A, B can be a tall array.
%   3) When SHAPE is "same" or "valid" B cannot be a tall array.
%
%   See also CONV, TALL.

%   Copyright 2016-2023 The MathWorks, Inc.


if nargin < 3
    shape = 'full';
else
    % SHAPE must not be tall and must be 'full', 'same', or 'valid'.
    tall.checkNotTall(upper(mfilename), 2, shape);
    try
        shape = validatestring(shape, {'full', 'same', 'valid'});
    catch
        % The error here depends on how the shape was wrong. For a
        % non-string CONV throws its own error. For strings that don't
        % match it reuses CONV2's error.
        if ischar(shape) || isstring(shape)
            error(message("MATLAB:conv2:unknownShapeParameter"));
        else
            error(message("MATLAB:conv:unknownShapeParameter"));
        end
    end
end
% Check for sparse
A = tall.validateNotSparse(A, "MATLAB:conv2:SparseInput");
B = tall.validateNotSparse(B, "MATLAB:conv2:SparseInput");
% Check input types - throws same as standard CONV
A = tall.validateTypeWithError(A, mfilename, 1, {'numeric', 'logical'}, "MATLAB:conv2:inputType");
B = tall.validateTypeWithError(B, mfilename, 2, {'numeric', 'logical'}, "MATLAB:conv2:inputType");

% Check tall-specific limitations

% Limitation 1: A and B must be columns
A = tall.validateColumn(A, "MATLAB:bigdata:array:ConvFirstArgNotColumnVector");
B = tall.validateColumn(B, "MATLAB:bigdata:array:ConvSecondArgNotColumnVector");

if shape == "full"
    % Limitation 2: For "full" either one can be tall but not both
    if istall(A) && istall(B)
        error(message("MATLAB:bigdata:array:ConvBothTall", upper(mfilename)));
    end
    % To keep things simple, make sure A is the tall input and B the
    % in-memory.
    if istall(B)
        [A,B] = deal(B,A);
    end
else
    % Limitation 3: For "same", "valid", A must be tall, B must be in-memory
    tall.checkIsTall(upper(mfilename), 1, A);
    tall.checkNotTall(upper(mfilename), 1, B);
end

if strcmpi(shape, 'full')
    % For non-row we can just use conv2
    C = convImpl(shape, A, B);
else
    C = ternaryfun(...
        iOutputIsRow(A, shape),...
        iConvRow(shape, A, B), ...
        convImpl(shape, A, B));
end
end

function isRow = iOutputIsRow(A, shape)
isRow = ~strcmpi(shape, 'full') & size(A,1) == 1;
end

function C = iConvRow(shape, A, B)
% For same and valid convolution, the output C will be a row vector when A
% is a scalar and the adaptor should already be setup for column output.
C = convImpl(shape, A, B);
rowAdaptor = setSizeInDim(C.Adaptor, 2, getSizeInDim(C.Adaptor,1));
rowAdaptor = setSizeInDim(rowAdaptor, 1, 1);
C = clientfun(@(x) x', C);
C.Adaptor = rowAdaptor;
end

