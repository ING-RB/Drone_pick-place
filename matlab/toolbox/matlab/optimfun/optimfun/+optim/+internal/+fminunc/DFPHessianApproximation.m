classdef DFPHessianApproximation < optim.internal.fminunc.AbstractDenseHessianApproximation
    % DFP Hessian approximation class
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    methods (Access = public)

        function this = DFPHessianApproximation(nVars)

        % Call superclass constructor
        this = this@optim.internal.fminunc.AbstractDenseHessianApproximation(nVars);
        end
    end

    methods (Access = protected)

        function this = updateHessian(this, deltaX, deltaGrad, deltaXDeltaGrad)

        % DFP update
        HdeltaGrad = this.Value * deltaGrad;
        this.Value = this.Value + ...
            deltaX*deltaX'/deltaXDeltaGrad - ...
            HdeltaGrad*HdeltaGrad'/(deltaGrad'*HdeltaGrad);
        end
    end
end
