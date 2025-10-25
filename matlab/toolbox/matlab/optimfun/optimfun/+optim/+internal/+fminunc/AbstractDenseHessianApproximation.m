classdef (Abstract) AbstractDenseHessianApproximation < optim.internal.fminunc.AbstractHessianApproximation
    % Abstract Hessian approximation class for methods that store a
    % dense approximation of the Hessian ('bfgs', 'dfp', and 'steepdesc')
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Value of the Hessian approximation
        Value % (:, :) double % Size: nVars x nVars
    end

    methods (Access = public)

        function this = AbstractDenseHessianApproximation(nVars)

        % Form initial inverse Hessian approximation
        this.Value = eye(nVars);
        end

        function dir = computeSearchDirection(this, grad)

        % Compute
        dir = -(this.Value * grad);
        end
    end

    methods (Access = protected)

        function [this, deltaXDeltaGrad, updateOk] = updatePreProcessing(this, deltaX, deltaGrad, iter)

        % Call superclass method
        [this, deltaXDeltaGrad, updateOk] = ...
            updatePreProcessing@optim.internal.fminunc.AbstractHessianApproximation(...
            this, deltaX, deltaGrad, iter);

        if iter == 1 && updateOk
            % Reset the initial quasi-Newton matrix to a scaled identity aimed
            % at reflecting the size of the inverse true Hessian
            this.Value = deltaXDeltaGrad/(deltaGrad'*deltaGrad)*eye(numel(deltaX));
        end
        end
    end
end
