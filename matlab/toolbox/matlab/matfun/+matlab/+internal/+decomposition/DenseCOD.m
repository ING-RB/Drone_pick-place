classdef DenseCOD < matlab.mixin.internal.Scalar
% DENSECOD   COD decomposition of a dense matrix
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2017-2023 The MathWorks, Inc.

    properties (Access = private)
        m_
        n_

        QR_
        Q1extra_
        perm_
        tau2_
    end

    properties (GetAccess = public, SetAccess = private)
        rank_ = [];
        ranktol_ = [];
    end

    methods
        function f = DenseCOD(A, tol)
            [f.m_,f.n_] = size(A);

            if f.m_ < f.n_
                A = A';
            end

            if isempty(tol)
                % Setting tol < 0 causes qrFactor to compute default tolerance from A.
                % Default tolerance is defined as:
                % If A is real:
                % tol = min(max(size(A))*eps(class(A)), sqrt(eps(class(A)))) * abs(R(1, 1))
                %
                % If A is complex:
                % tol = min(10*max(size(A))*eps(class(A)), sqrt(eps(class(A)))) * abs(R(1, 1))

                tol = -2;
            end

            % Construct object.
            [f.QR_,f.Q1extra_,f.perm_,f.rank_,f.ranktol_] = ...
                matlab.internal.decomposition.builtin.qrFactor(A, tol);

            if f.rank_ < min(f.m_, f.n_)
                [f.QR_, f.tau2_] = ...
                    matlab.internal.decomposition.builtin ...
                    .codFactor(f.QR_, f.rank_);
            end

        end

        function x = solve(f,b,transposed)

            if f.m_ < f.n_
                % The internally computed decomposition always has m >= n
                transposed = ~transposed;
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
            x = matlab.internal.decomposition.builtin.codSolve(f.QR_, f.Q1extra_, f.tau2_, f.rank_, b, transposed, f.perm_);

        end
    end
end
