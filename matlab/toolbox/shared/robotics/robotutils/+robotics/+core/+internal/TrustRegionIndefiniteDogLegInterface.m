classdef TrustRegionIndefiniteDogLegInterface < robotics.core.internal.NLPSolverInterfaceUnconstrained
%This class is for internal use only. It may be removed in the future.

%TRUSTREGIONINDEFINITEDOGLEGINTERFACE

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

    properties (Abstract, Dependent, SetAccess = protected)

        %Name Name of the solver
        Name

    end

    properties (Access = protected)

        %GradientTolerance Tolerance on the first order optimality
        %   The solver terminates if the norm of the gradient falls below
        %   this value (a positive value)
        GradientTolerance

        %FunctionTolerance Tolerance on function value
        %   The solver terminates if the change in the scalar cost
        %   function within a step falls below this value (a positive
        %   value)
        FunctionTolerance

        %InitialTrustRegionRadius Initial trust region radius
        InitialTrustRegionRadius

        %TrustRegionRadiusTolerance Tolerance on trust region radius
        %   The solver terminates if the trust region radius falls below
        %   this positive value
        TrustRegionRadiusTolerance

        %IsVerbose Display Iteration Information, a Boolean
        IsVerbose

        %SkipPDCheck Setting this flag will disable the positive definiteness
        %   check when solving the linear system
        SkipPDCheck
    end

    methods
        function obj = TrustRegionIndefiniteDogLegInterface()
        %TrustRegionIndefiniteDogLegInterface Constructor
            obj.MaxNumIteration = 300;
            obj.MaxTime = 10;

            obj.StepTolerance = 1e-12;
            obj.GradientTolerance = 0.5e-8;
            obj.FunctionTolerance = 1e-15;
            obj.InitialTrustRegionRadius = 10;
            obj.TrustRegionRadiusTolerance = 1e-10;
            obj.IsVerbose = false;


            obj.TimeObj = robotics.core.internal.SystemTimeProvider();
        end

        function params = getSolverParams(obj)
        %getSolverParams
            params.Name = obj.Name;
            params.MaxNumIteration = obj.MaxNumIteration;
            params.MaxTime = obj.MaxTime;
            params.GradientTolerance = obj.GradientTolerance;
            params.StepTolerance = obj.StepTolerance;
            params.FunctionTolerance = obj.FunctionTolerance;
            params.InitialTrustRegionRadius = obj.InitialTrustRegionRadius;
            params.TrustRegionRadiusTolerance = obj.TrustRegionRadiusTolerance;
            params.IsVerbose = obj.IsVerbose;
        end

        function setSolverParams(obj, params)
        %setSolverParams
            obj.MaxNumIteration =       params.MaxNumIteration;
            obj.MaxTime =               params.MaxTime;
            obj.GradientTolerance =     params.GradientTolerance;
            obj.StepTolerance =         params.StepTolerance;
            obj.FunctionTolerance =     params.FunctionTolerance;
            obj.InitialTrustRegionRadius   = params.InitialTrustRegionRadius;
            obj.TrustRegionRadiusTolerance = params.TrustRegionRadiusTolerance;
            obj.IsVerbose =             params.IsVerbose;
        end

        function newobj = copy(obj)
        %COPY
            newobj = obj.getDefaultObject;

            newobj.SeedInternal = obj.SeedInternal;
            newobj.MaxTimeInternal = obj.MaxTimeInternal;
            newobj.MaxNumIterationInternal = obj.MaxNumIterationInternal;

            newobj.CostFcn = obj.CostFcn;

            newobj.ExtraArgs = obj.ExtraArgs;

            newobj.setSolverParams(obj.getSolverParams);

            newobj.TimeObj = obj.TimeObj;
        end

    end

    methods (Abstract, Access = protected)

        [x, xSol] = initializeInternal(obj)
        xSol = updateSolution(obj, x)
        [lambda, v] = eigSmallest(obj, B)
        xnew = incrementX(obj, x, step)
        defaultObj = getDefaultObject(obj)

    end

    methods (Access = {?robotics.core.internal.NLPSolverInterfaceUnconstrained, ...
                       ?matlab.unittest.TestCase})

        function [xSol, exitFlag, cost, iter, B] = solveInternal(obj)
        %solveInternal

            [x, xSol] = obj.initializeInternal;
            iter = 0;

            % Initializing exit flag with some value for Codegeneration. It
            % will be updated if any other exit criteria is met
            exitFlag = robotics.core.internal.NLPSolverExitFlags.IterationLimitExceeded;

            % initialize cost, gradient and Hessian (or Hessian approximate)
            [cost, grad, Hessian] = obj.CostFcn(x, obj.ExtraArgs);
            B = Hessian;

            % initialize trust region radius
            delta = obj.InitialTrustRegionRadius;

            [stepSD, stepGN, negcurv, localMin] = computeBasicSteps(obj, grad, B);
            % EXIT condition: if initial guess is already at local min
            if localMin
                exitFlag = robotics.core.internal.NLPSolverExitFlags.LocalMinimumFound;
                return;
            end
            terminated = false;
            % main iteration loop
            for i = 1:obj.MaxNumIterationInternal
                % EXIT condition: max time reached
                if timeLimitExceeded(obj, obj.TimeObj.getElapsedTime)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.TimeLimitExceeded;
                    terminated = true;
                    break;
                end

                % compute dogleg step
                [stepDL, forceReject] = computeDogLegStep(obj, stepSD, stepGN, B, negcurv, delta);


                % EXIT condition: minimum step size
                if stepSizeBelowMinimum(obj, stepDL)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.StepSizeBelowMinimum;
                    terminated = true;
                    break;
                end

                % take a trial (dogleg) step
                xn = obj.incrementX(x, stepDL);
                [costTrial, gradTrial, HessianTrial] = obj.CostFcn(xn, obj.ExtraArgs);

                % EXIT condition: minimum change in cost
                if changeInCostBelowMinimum(obj, cost, costTrial)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.ChangeInErrorBelowMinimum;
                    terminated = true;
                    break;
                end

                % compute change in cost function
                DF = cost - costTrial;

                % change in second-order approximation of cost function
                DL = -stepDL'*(grad + 0.5*B*stepDL);

                rho = DF/DL;
                if (~forceReject) && rho > 0 % accept the step
                    x = obj.incrementX(x, stepDL);
                    iter = i;
                    cost = costTrial;
                    grad = gradTrial;
                    B = HessianTrial;

                    if coder.target('matlab')
                        if obj.IsVerbose
                            msg = getString(message('shared_robotics:optim:DisplayIterationInformation', num2str(iter), sprintf('%f', cost)));
                            fprintf('%s\n', msg);
                        end
                    end

                    [stepSD, stepGN, negcurv, localMin] = computeBasicSteps(obj, grad, B);
                    % EXIT condition: if current step is already at local min
                    if localMin
                        exitFlag = robotics.core.internal.NLPSolverExitFlags.LocalMinimumFound;
                        terminated = true;
                        break;
                    end
                end


                % adjust trust region
                [delta, trustRegionToolSmall] = adjustTrustRegionRadius(obj, forceReject, stepDL, rho, delta);
                % EXIT condition: trust region radius too small
                if trustRegionToolSmall
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.TrustRegionRadiusBelowMinimum;
                    terminated = true;
                    break;
                end

            end

            % Filling the output object outside of for loop for
            % Codegeneration
            xSol = obj.updateSolution(x);
            if ~terminated
                % EXIT condition: maximum iteration reached. Updating iter
                % for this condition.
                iter = obj.MaxNumIterationInternal;
            end
        end


        function [stepSD, stepGN, negcurv, localMin] = computeBasicSteps(obj, grad, B)
        %computeBasicSteps (stepSD, stepGN, negcurv)
            localMin = false;
            negcurv = grad;
            n = numel(grad);
            if obj.SkipPDCheck
                alpha = (grad'*grad)/(grad'*B*grad);
                stepSD = alpha*(-grad); % SD = steepest descent

                stepGN = B\(-grad); % GN = Gauss Newton

                if atLocalMinimum(obj,grad)
                    localMin = true;
                    return;
                end
            elseif robotics.core.internal.isPositiveDefinite(B)
                % compute alpha, the step length along negative grad direction
                alpha = (grad'*grad)/(grad'*B*grad);
                stepSD = alpha*(-grad); % SD = steepest descent

                stepGN = B\(-grad); % GN = Gauss Newton

                if atLocalMinimum(obj,grad)
                    localMin = true;
                    return;
                end
            else
                [lambda1, v] = eigSmallest(obj, B);
                if lambda1 == 0
                    stepSD = -grad;
                    stepGN = -grad;
                else
                    negcurv = v; % direction of negative curvature, for later

                    if negcurv(1) > 0 % needed to ensure the same results from MATLAB execution and MEX/DLL
                        negcurv = - negcurv;
                    end

                    Bm = B + 1.5*(-lambda1)*eye(n);
                    alpha = (grad'*grad)/(grad'*Bm*grad);
                    stepSD = alpha*(-grad); % SD = steepest descent

                    stepGN = Bm\(-grad); % GN = Gauss Newton
                end

            end

        end

        function [stepDL, forceReject] = computeDogLegStep(obj, stepSD, stepGN, B, negcurv, delta)
        %computeDogLegStep
            forceReject = false;
            if norm(stepSD) >= delta
                stepDL_ = (delta/norm(stepSD))*stepSD;
            elseif norm(stepGN) <= delta
                if obj.SkipPDCheck
                    stepDL_ = stepGN;
                elseif robotics.core.internal.isPositiveDefinite(B)
                    stepDL_ = stepGN;
                else
                    c = negcurv;
                    d = stepGN;
                    if c'*d < 0 % if negcurv direction completely disagrees with GN
                        forceReject = true;
                    end
                    dtc = d'*c;
                    ctc = c'*c;
                    dtd = d'*d;
                    beta = ( -dtc + sqrt( dtc^2 + ctc*(delta^2 - dtd)))/ctc;
                    stepDL_ = stepGN + beta*negcurv;

                end


            else % when stepSD < delta < stepGN
                 % compute beta, step length along GN direction
                c = stepSD'*(stepGN-stepSD);
                d = stepGN-stepSD;
                dtd = d'*d;
                beta = (-c + sqrt(c*c + dtd*(delta^2 - norm(stepSD)^2) ) )/dtd;

                stepDL_ = stepSD + beta*(stepGN-stepSD);

            end
            stepDL = real(stepDL_);
        end


        function [delta, trustRegionToolSmall] = adjustTrustRegionRadius(obj, forceReject, stepDL, rho, delta)
        %adjustTrustRegionRadius
            trustRegionToolSmall = false;
            if forceReject == false
                if rho > 0.75 && norm(stepDL) > 0.9*delta % expand trust region
                    delta = 2*norm(stepDL); %max(delta, 2*norm(stepDL));
                elseif rho < 0.25 % shrink trust region
                    delta = delta/4;

                    if trustRegionRaiusBelowMinimum(obj, delta)
                        trustRegionToolSmall = true;
                        return;
                    end
                end
            else % also shrink trust region if negcurv direction not acceptable
                delta = delta/4;
                if trustRegionRaiusBelowMinimum(obj, delta)
                    trustRegionToolSmall = true;
                    return;
                end
            end
        end


        function flag = atLocalMinimum(obj, grad)
            flag = norm(grad) < obj.GradientTolerance;
        end

        function flag = changeInCostBelowMinimum(obj, cost, costnew)
            flag = all(abs(cost - costnew) < obj.FunctionTolerance);
        end

        function flag = stepSizeBelowMinimum(obj, step)
            flag = all(abs(step) < obj.StepTolerance);
        end

        function flag = trustRegionRaiusBelowMinimum(obj, delta)
        % delta is always a positive scalar
            flag = delta < obj.TrustRegionRadiusTolerance;
        end
    end

    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
        % Let the coder know about non-tunable parameters
            props = {'SkipPDCheck'};
        end
    end

end
