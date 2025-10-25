classdef SteepestDescentHessianApproximation < optim.internal.fminunc.AbstractDenseHessianApproximation
    % Steepest descent Hessian approximation class
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    methods (Access = public)

        function this = SteepestDescentHessianApproximation(nVars)

        % Call superclass constructor
        this = this@optim.internal.fminunc.AbstractDenseHessianApproximation(nVars);
        end

        function [this, msg] = update(this, deltaX, ~, ~)

        % Override superclass method. No pre-processing required
        this = this.updateHessian(deltaX);
        msg = '';
        end
    end

    methods (Access = protected)

        function this = updateHessian(this, deltaX)

        % Steepest descent
        this.Value = eye(numel(deltaX));
        end
    end
end
