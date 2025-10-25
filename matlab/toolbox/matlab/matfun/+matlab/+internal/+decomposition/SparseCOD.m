classdef SparseCOD < matlab.mixin.internal.Scalar
    % SPARSECOD   COD decomposition of a sparse matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Access = private)
        m_
        n_
        
        % First matrix Q (along the larger dimension of A)
        H1
        tau1
        rowperm1
        colperm1
        
        % Second matrix Q (only needed for low-rank case)
        H2
        tau2
        rowperm2
        colperm2

        % Third matrix Q (only needed for regularization)
        H3
        tau3
        rowperm3
        colperm3
        
        % Internal matrix R (size f.rank_-by-f.rank_)
        R
        Rtransposed = false
             
        % Save inputs
        tol_
        useMinDegree_
    end
    
    properties (GetAccess = public, SetAccess = private)
        rank_ = [];
        ranktol_ = [];
    end
    
    methods
        function f = SparseCOD(A, tol, useMinDegree, lambda)
            if nargin < 4
                lambda = 0;
            end
            [f.m_,f.n_] = size(A);

            if f.m_ < f.n_
                A = A';
                f.Rtransposed = true;
            else
                % lambda is only used from lsqminnorm, which only calls SparseCOD
                % when f.m_ < f.n_
                assert(lambda == 0, 'Only expecting regularization with underdetermined systems.');
            end
            
            if isempty(tol)
                % Use SPQR default tolerance:
                % tol = min(20*sum(size(A))*eps*max(sqrt(sum(abs(A).^2, 1))), realmax)
                if isa(A, 'single')
                    % While SPQR does not support single natively, we need
                    % to set this tolerance explicitly
                    f.tol_ = matlab.internal.math.getTolForSPQR(A);
                else
                    f.tol_ = -2;
                end
            else
                f.tol_ = tol;
            end
            f.useMinDegree_ = useMinDegree;
            
            % Construct object.
            [f.H1, f.tau1, f.rowperm1, f.R, f.colperm1, f.rank_, f.ranktol_] = ...
                matlab.internal.math.implicitSparseQR(A, useMinDegree, f.tol_);
            
            if f.rank_ < min(f.m_, f.n_)
                %  If we are regularizing, we are in one of two situations: if
                %  the regularization is above the rank tolerance, then it is
                %  enough to force the augmented system to be full rank.  If it
                %  is below the rank tolerance, the regularization effectively
                %  does nothing, so we can proceed as if it were 0.
                if lambda < f.ranktol_
                    lambda = 0;
                end
                if lambda > 0
                    f.rank_ = min(f.m_, f.n_);
                end
                % If the system is rank deficient, we reduce dimensions.
                if f.rank_ < min(f.m_, f.n_)
                    M = f.R;
                    M(f.rank_+1:end, :) = [];
                    
                    [f.H2, f.tau2, f.rowperm2, f.R, f.colperm2] = ...
                        matlab.internal.math.implicitSparseQR(M', useMinDegree, 0);
                    
                    f.rowperm2(f.colperm1) = f.rowperm2;
                    f.colperm1 = [];
                    f.Rtransposed = ~f.Rtransposed;
                end
            end
            % Compute the factorization of the R factor.
            if lambda ~= 0
                % Build augmented R factor.
                % At this point, we are assuming we are transposed because
                % this API is only invoked for undetermined systems.
                f.R = f.R(1:f.rank_, :);
                f.R(:, f.colperm1) = f.R;
                f.colperm1 = [];
                [i,j] = find(f.R);
                rv = [nonzeros(f.R); repelem(lambda, f.rank_, 1)];
                idx = [j; f.rank_ + (1:f.rank_)'];
                jdx = [i; (1:f.rank_)'];
                rv = conj(rv);
                % Raug = [R'; lambda*speye(f.rank_)];
                Raug = sparse(idx, jdx, rv, 2*f.rank_, f.rank_, numel(rv));
                % Compute factorization.
                [f.H3, f.tau3, f.rowperm3, f.R, f.colperm3] = ...
                    matlab.internal.math.implicitSparseQR(Raug, useMinDegree, 0);
                f.Rtransposed = false;
            end
        end
        
        function x = solve(f,b,transposed)
            
            isValidRegularization = isempty(f.colperm3) || ...
                ((f.m_ < f.n_) && ~transposed);
            assert(isValidRegularization, ...
                'Only expecting regularization with underdetermined systems and non-transposed solves.');
            if xor(transposed, f.m_ >= f.n_)
                applyQ_reduce = @applyQ1;
                p_reduce = f.colperm2;
                applyQ_extend = @applyQ2;
                p_extend = f.colperm1;
            else
                if ~isempty(f.colperm3)
                    b = [b; zeros(f.rank_, size(b,2), 'like', b)];
                    applyQ_reduce = @applyQ3;
                    p_reduce = f.colperm1;
                    applyQ_extend = @applyQ1;
                    p_extend = f.colperm3;
                else
                    applyQ_reduce = @applyQ2;
                    p_reduce = f.colperm1;
                    applyQ_extend = @applyQ1;
                    p_extend = f.colperm2;
                end
            end
            
            x = applyQ_reduce(f, b, true);
            
            if isempty(p_reduce)
                x = x(1:f.rank_, :);
            else
                x = x(p_reduce, :);
            end

            x2 = matlab.internal.decomposition.builtin.sparseTriangSolve(f.R, x, 'upper', transposed ~= f.Rtransposed);

            if ~transposed
                x = zeros(f.n_, size(b, 2), 'like', b);
            else
                x = zeros(f.m_, size(b, 2), 'like', b);
            end
            if isempty(p_extend)
                x(1:f.rank_, :) = x2;
            else
                x(p_extend, :) = x2;
            end
            
            x = applyQ_extend(f, x, false);
        end
    end
    
    methods(Access = private)
        
        function y = applyQ1(f, x, transp)
            % Compute y = Q*x or y = Q'*x, where Q is a square
            % orthogonal matrix defined by Householder vectors.
            
            y = applyQ(f.H1, f.tau1, f.rowperm1, x, transp);
        end
        
        function y = applyQ2(f, x, transp)
            % Compute y = Q*x or y = Q'*x, where Q is a square
            % orthogonal matrix defined by Householder vectors.
            
            if f.rank_ == min(f.m_, f.n_)
                y = x;
            else
                y = applyQ(f.H2, f.tau2, f.rowperm2, x, transp);
            end
        end

        function y = applyQ3(f, x, transp)
            % Compute y = Q*x or y = Q'*x, where Q is a square
            % orthogonal matrix defined by Householder vectors.
            
            y = applyQ(f.H3, f.tau3, f.rowperm3, x, transp);

        end

    end
end


function y = applyQ(H, tau, rowperm, x, transp)
% Compute y = Q*x or y = Q'*x, where Q is a square
% orthogonal matrix defined by Householder vectors.

if isreal(H) && isreal(tau) && ~isreal(x)
    % Real Q applied to complex x not supported in built-in
    y = matlab.internal.math.applyHouseholder(H, tau, rowperm, real(x), transp) + ...
        1i*matlab.internal.math.applyHouseholder(H, tau, rowperm, imag(x), transp);
else
    y = matlab.internal.math.applyHouseholder(H, tau, rowperm, x, transp);
end
end
