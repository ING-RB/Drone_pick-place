function x = lsqminnorm(A, b, varargin)
%LSQMINNORM Minimum-norm solution of least-square system
%    X = LSQMINNORM(A, B) returns a vector X that minimizes norm(A*X - B).
%    If there are many solutions X to this problem, then the solution with
%    minimal norm(X) is returned. If B has multiple columns, the previous
%    statements are true for each column of X and B, respectively.
%
%    X = LSQMINNORM(A, B, TOL) additionally specifies the tolerance, which
%    is used to determine the rank of A. By default, TOL is computed based
%    on the QR decomposition of A.
%
%    LSQMINNORM(A, B, TOL) is a possible alternative to PINV(A, TOL) * B.
%    It is supported for sparse matrices, and is typically more efficient.
%    The two functions are not exactly equivalent, since LSQMINNORM uses
%    the Complete Orthogonal Decomposition (COD) to find a low-rank
%    approximation of A, while PINV uses the Singular Value Decomposition
%    (SVD).
%
%    X = LSQMINNORM(..., RANKWARN) specifies whether LSQMINNORM should
%    produce a warning when the matrix A is detected to be of low rank.
%    RANKWARN can be:
%        'nowarn' - (default) No warning is given if A has low rank.
%          'warn' - A warning is given if A has low rank.
%
%    X = LSQMINNORM(..., RegularizationFactor=lambda) applies Tikhonov
%    regularization to the least-squares solution, returning a solution X that
%    minimizes norm(A*X-B)^2 + lambda^2*norm(X)^2 for each column of X.
%    For ill-conditioned systems, this gives preference to solutions X with
%    smaller norm.
%
%    See also: PINV, DECOMPOSITION, PAGELSQMINNORM

%   Copyright 2017-2024 The MathWorks, Inc.

narginchk(2, inf);

tol = -2; % this signals to internal classes to use default tolerance
checkCondition = false;

if ~isfloat(A)
    error(message('MATLAB:lsqminnorm:InvalidA'));
end

if ~isfloat(b)
    error(message('MATLAB:decomposition:InvalidB'));
end

if ~ismatrix(A) || ~ismatrix(b)
    error(message('MATLAB:lsqminnorm:inputMustBe2D'))
end

lambda = 0;
if nargin > 2
    nTrailingArgs = numel(varargin);
    offset = 1;
    % Check for tolerance.
    if isnumeric(varargin{offset})
        tol = varargin{1};
        if ~isscalar(tol) || ~isreal(tol) || ~isfloat(tol) || ~(tol >= 0)
            error(message('MATLAB:lsqminnorm:InvalidTol'));
        end
        offset = offset+1;
    end
    % Check for warn / nowarn flags
    if offset <= nTrailingArgs
        name = varargin{offset};
        if matlab.internal.math.partialMatch(name, 'warn')
            checkCondition = true;
            offset = offset + 1;
        elseif matlab.internal.math.partialMatch(name, 'nowarn')
            checkCondition = false;
            offset = offset + 1;
        end
    end
    % Check trailing name-value pairs.
    for i = offset:2:nTrailingArgs
        name = varargin{i};
        if ~matlab.internal.math.partialMatch(name, 'RegularizationFactor')
            error(message('MATLAB:lsqminnorm:BadNVPair'));
        end
        if i == nTrailingArgs
            error(message('MATLAB:lsqminnorm:NeedNVPairs'));
        end
        value = varargin{i+1};
        if ~(isscalar(value) && isreal(value) && isfinite(value) && (value >= 0) && isfloat(value))
            error(message('MATLAB:lsqminnorm:BadRegValue'))
        end
        lambda = value;
    end
end

castBack = @(x) x;
if isa(A, 'single') ~= isa(b, 'single')
    support = matlab.internal.feature("SingleSparse");
    if ~support && (issparse(A) || issparse(b))
        error(message('MATLAB:mldivide:sparseSingleNotSupported'));
    end
    if isa(b, 'single')
        % Note: A\b would cast matrix A to single - but here the decomposition
        % is already done in double, so return x = single( dA\double(b) ) instead.
        b = double(b);
        castBack = @single;
    else
        b = single(b);
    end
end
lambda = cast(lambda, "like", b);

if ~issparse(A) && issparse(b)
    b = full(b);
end

if size(b, 1) ~= size(A, 1)
    error(message('MATLAB:decomposition:mldivide'));
end

[m, n] = size(A);
if ~issparse(A)

    if m < n
        A = A';
    end

    % QR decomposition of A: A = Q*R*P
    [QR,Q1extra,perm,k,ranktol] = matlab.internal.decomposition.builtin.qrFactor(A, tol);

    if k < min(m, n)
        %  If we are regularizing, we are in one of two situations: if the
        %  regularization is above the rank tolerance, then it is enough to
        %  force the augmented system to be full rank.  If it is below the
        %  rank tolerance, the regularization effectively does nothing, so
        %  we can proceed as if it were 0.
        if lambda < ranktol
            lambda = 0;
        end
        if lambda ~= 0
            % Regularization is enough to force R to be full rank.
            k = min(m,n);
            tau2 = [];
            [QR, Qaug, tau3] = matlab.internal.decomposition.builtin.qrFactorBlockTriangular(QR, k, lambda, m < n);
        else
            % Second QR factorization of R(1:k, :)'
            % A = Qlong * R(1:k, 1:k) * Qshort' * P
            [QR, tau2] = matlab.internal.decomposition.builtin.codFactor(QR, k);
        end
    else
        tau2 = [];
        if lambda ~= 0
            % If we are reguarlizing, then we need to compute the QR
            % decomposition of the R factor, allowing us to solve the system
            % [R; lambda*I] \ [Qlong'*b; 0] if we did not transpose A, or
            % [R'; lambda*I] \ [Qshort'*b; 0] if we did.
            [QR, Qaug, tau3] = matlab.internal.decomposition.builtin.qrFactorBlockTriangular(QR, k, lambda, m < n);
        end
    end

    % If we transposed A, then we
    %   Solve Qlong * R * Qshort' * x = b, using formula
    %   x = (Qshort * (R \ (Qlong' *b) ) )
    %   Next, we apply the permutation to x
    %   x(perm,:) = x
    % Otherwise, we do the following
    %   Apply our permutation to b
    %   b = b(perm,:)
    %   Then, solve Qshort * R' * Qlong' * x = b, using formula
    %   x = (Qlong * (R' \ (Qshort' *b) )
    if lambda ~= 0
        x = matlab.internal.decomposition.builtin.codSolve(QR, Q1extra, tau2, k, b, m < n, perm, Qaug, tau3);
    else
        x = matlab.internal.decomposition.builtin.codSolve(QR, Q1extra, tau2, k, b, m < n, perm);
    end

    if checkCondition && k < min(size(A))
        warning(message('MATLAB:rankDeficientMatrix',sprintf('%d',k),sprintf('%13.6e',ranktol)));
    end

else % issparse(A)
    % While SPQR does not support single natively, we need to set this tolerance explicitly
    % if not provided
    if isa(b,'single') && tol == -2
        tol = matlab.internal.math.getTolForSPQR(A);
    end

    if m < n
        dA = matlab.internal.decomposition.SparseCOD(A, double(tol), true, lambda);

        x = solve(dA, b, false);

        if checkCondition && dA.rank_ < min(size(A))
            warning(message('MATLAB:rankDeficientMatrix',sprintf('%d',dA.rank_),sprintf('%13.6e',dA.ranktol_)));
        end
    else

        % More efficient variant without using internal decomposition objects
        % This avoids having to store the Householder vectors even implicitly
        [R, colperm1, QTb, rank_, ranktol_] = ...
            matlab.internal.math.sparseQRnoQ(A, true, double(tol), b);

        if lambda < ranktol_
            lambda = 0;
        end
        if lambda > 0
            rank_ = min(m,n);
        end

        if rank_ == min(m, n)
            x = QTb(1:rank_, :);

            if lambda == 0
                % x2 = R(1:rank_, 1:rank_) \ x;
                x2 = matlab.internal.decomposition.builtin.sparseTriangSolve(R(1:rank_,1:rank_), x, 'upper', false);
            else
                % [Q2,R2] = qr([R(1:rank_, 1:rank_); lambda*I]);
                % x2 = R2(1:rank_,1:rank_)\(Q2'*[x; 0]);
                [i,j] = find(R);
                rv = [nonzeros(R); repmat(lambda,rank_,1)];
                i = [i; rank_ + (1:rank_)'];
                j = [j; (1:rank_)';];
                R = sparse(i, j, rv, 2*rank_, rank_, numel(rv));
                x = [x; zeros(rank_, size(x,2), "like", x)];
                [R, colperm2, QTx] = matlab.internal.math.sparseQRnoQ(R, true, 0, x);
                x = QTx(1:rank_,:);
                x2 = matlab.internal.decomposition.builtin.sparseTriangSolve(R(1:rank_,1:rank_), x, 'upper', false);
                x2(colperm2,:) = x2;
            end

            x = zeros(n, size(b, 2), "like", b);

            x(colperm1, :) = x2;

        else

            if checkCondition
                warning(message('MATLAB:rankDeficientMatrix',sprintf('%d',rank_),sprintf('%13.6e',ranktol_)));
            end

            M = R;
            M(rank_+1:end, :) = [];

            [H2, tau2, rowperm2, R, colperm2] = ...
                matlab.internal.math.implicitSparseQR(M', true, 0);

            rowperm2(colperm1) = rowperm2;

            x = QTb(colperm2, :);

            %x2 = R' \ x;
            x2 = matlab.internal.decomposition.builtin.sparseTriangSolve(R, x, 'upper', true);

            x = zeros(n, size(b, 2), "like", b);

            x(1:rank_, :) = x2;

            if rank_ < min(m, n)
                if isreal(H2) && isreal(tau2) && ~isreal(x)
                    % Real Q applied to complex x not supported in built-in
                    x = matlab.internal.math.applyHouseholder(H2, tau2, rowperm2, real(x), false) + ...
                        1i*matlab.internal.math.applyHouseholder(H2, tau2, rowperm2, imag(x), false);
                else
                    x = matlab.internal.math.applyHouseholder(H2, tau2, rowperm2, x, false);
                end
            end
        end
    end
end

x = castBack(x);

end
