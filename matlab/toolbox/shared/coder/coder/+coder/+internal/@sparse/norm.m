function n = norm(this, P)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(P);

cls = class(this.d);
coder.internal.assert(isa(this.d,'float'), ...
    'Coder:toolbox:unsupportedClass','norm',cls);

if nargin < 2
    P = 2;
elseif isnan(P)
    n = coder.internal.nan(cls);
    return
end
n = zeros('like',this.d);
if (numel(this) == 0)
    % Empty sparse input, short circuit
    return
end

nz = nnz(this);

VECTOR_INPUT = (this.m == 1 || this.n == 1);
if VECTOR_INPUT
    if P == 0
        % Special case for 0-norm
        if (nz ~= 0)
            % If there are non-zero elements check if any of them
            % are nan
            if anynan(this.d)
                n = coder.internal.nan(cls);
            end
        end
        if ~isnan(n)
            if numel(this) > 1
                n = coder.internal.inf(cls);
            else
                n = cast(numel(this),'like',this.d);
            end
        end
        return
    end
    if (nz ~= 0)
        % Execute the norm call only if there are non-zero elements in the
        % vector.
        n = norm(this.d,P);
    end
    % P is validated by norm call, check if it is -inf
    if coder.internal.isBuiltInNumeric(P) && isinf(P) && sign(P)<0
        % in case of P==-inf, return 0 if sparse vector has atleast
        % 1 zero.
        if nz ~= numel(this) && (~isnan(n)) % If the data has nans, return nan
            n = zeros('like',this.d);
        end
    end
    return
end

if (nz == 0)
    % All zero sparse matrix, short circuit
    return
end

P_IS_VALID = false;
MATRIX_INPUT_AND_P_IS_ONE = false;
MATRIX_INPUT_AND_P_IS_TWO = false;
MATRIX_INPUT_AND_P_IS_INF = false;

if coder.internal.isTextRow(P)
    if coder.internal.matchStringParameter(P,'fro')
        % Frobenius norm can be defined as a function of the sum of
        % the elements of a matrix. The norm is independent of the shape of the
        % matrix
        n = norm(this.d,P);
        return
    elseif coder.internal.matchStringParameter(P,'inf')
        P_IS_VALID = true;
        MATRIX_INPUT_AND_P_IS_INF = true;
    end
elseif coder.internal.isBuiltInNumeric(P) && isscalar(P)
    % Safe to assume only matrix inputs end up here
    p = real(P(1));
    if ~isreal(P) && imag(P) ~= 0
        % Complex P is not supported.
    elseif p == 1
        P_IS_VALID = true;
        MATRIX_INPUT_AND_P_IS_ONE = true;
    elseif p == 2
        P_IS_VALID = true;
        MATRIX_INPUT_AND_P_IS_TWO = true;
    elseif isa(p,'float') && p > 0 && isinf(p)
        P_IS_VALID = true;
        MATRIX_INPUT_AND_P_IS_INF = true;
    end
end

coder.internal.assert(P_IS_VALID, 'MATLAB:norm:unknownNorm');
% Error for 2-norm only when the matrix is not zero-dimensional
coder.internal.errorIf(numel(this)~=0 && MATRIX_INPUT_AND_P_IS_TWO, ...
    'MATLAB:norm:spNorm2notAvailable');

if MATRIX_INPUT_AND_P_IS_ONE
    % max(sum(abs(x)))
    n = zeros('like', this.d);
    for j = 1:this.n
        colMax = zeros('like', this.d);
        for k = this.colidx(j):(this.colidx(j+1)-1)
            colMax = colMax + abs(this.d(k));
        end
        if isnan(colMax)
            n = coder.internal.nan(cls);
            return
        elseif colMax > n
            n = colMax;
        end
    end
else
    % max(sum(abs(x')))
    assert(MATRIX_INPUT_AND_P_IS_INF)
    % Can be implemented as a recursive call
    % norm(this',1). However, transpose creates a copy in
    % codegen. Store a temporary vector of
    % row sums to calculate norm(this,inf)
    rowMax = zeros(this.m,1,'like',this.d);
    for i = 1:nz
        ridx = this.rowidx(i);
        rowMax(ridx) = rowMax(ridx) + abs(this.d(i));
    end
    for i = 1:this.m
        if isnan(rowMax(i))
            n = coder.internal.nan(cls);
            return
        elseif n < rowMax(i)
            n = rowMax(i);
        end
    end
end