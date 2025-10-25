classdef DenseQR < matlab.mixin.internal.Scalar
    % DENSEQR   QR decomposition of a dense matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2022 The MathWorks, Inc.
    
    properties (Access = private)
        m_
        n_
        QR_
        Qextra_
        perm_
    end
    
    properties (GetAccess = public, SetAccess = private)
        rank_ = [];
        ranktol_ = [];
    end
    
    methods
        function f = DenseQR(A, tol)
            [f.m_,f.n_] = size(A);
            
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
            [f.QR_,f.Qextra_,f.perm_,f.rank_,f.ranktol_] = ...
                matlab.internal.decomposition.builtin.qrFactor(A, tol);
        end
        
        function x = solve(f,b,~)
            x = matlab.internal.decomposition.builtin.qrSolve(...
                f.QR_, f.Qextra_, f.perm_, b, f.rank_);
        end
    end
end
