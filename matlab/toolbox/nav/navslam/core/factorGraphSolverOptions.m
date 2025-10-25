classdef factorGraphSolverOptions
%FACTORGRAPHSOLVEROPTIONS Solver options for optimizing factor graph
%
%   OPTS = FACTORGRAPHSOLVEROPTIONS returns a factor graph solver options
%   object, OPTS.
%
%   OPTS = FACTORGRAPHSOLVEROPTIONS(Name=Value) specifies properties using
%   one or more name-value arguments.
%
%   FACTORGRAPHSOLVEROPTIONS properties:
%       MaxIterations           - Max number of solver iterations
%       FunctionTolerance       - Lower bound of change in cost function
%       GradientTolerance       - Lower bound of norm of gradient
%       StepTolerance           - Lower bound of step size
%       VerbosityLevel          - Flag to change command line verbosity
%       TrustRegionStrategyType - Flag to change trust region step
%                                 computation algorithm
%       StateCovarianceType     - Flag to enable state covariance
%                                 estimation
%       InitialTrustRegionRadius- Initial trust region radius
%
%   Example:
%       % Create a factor graph and add a GPS factor
%       G = factorGraph;
%       f = factorGPS(1,ReferenceFrame="NED");
%       addFactor(G,f);
%       % Create solver options with custom settings. Set the maximum
%       % number of iterations to 100 
%       opts = factorGraphSolverOptions(MaxIterations=100);
%       % Optimize the factor graph with the custom settings
%       optimize(G,opts);
%
%   See also factorGraph, importFactorGraph, factorGPS, factorIMU

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

    properties
        %MaxIterations Maximum number of solver iterations allowed
        %   Default: 200
        MaxIterations = 200

        %FunctionTolerance Lower bound on the change in cost function
        %   |newCost - oldCost| < FunctionTolerance * oldCost 
        %   (costs are always > 0)
        %
        %   Default: 1e-6
        FunctionTolerance = 1e-6

        %GradientTolerance Lower bound on the norm of gradient
        %   max_norm{ x - [x Oplus -g(x)] } <= GradientTolerance, where
        %   Oplus is the manifold version of the plus operation, and g(x)
        %   is the gradient at x. 
        %
        %   Default: 1e-10
        GradientTolerance = 1e-10

        %StepTolerance Lower bound on the step size
        %   |deltaX| <= (|x| + StepTolerance) * StepTolerance, where
        %   deltaX is the step computed by the linear solver
        %   Default: 1e-8
        StepTolerance = 1e-8

        %VerbosityLevel Controls commandline message verbosity
        %   0 - No printing
        %   1 - With solver summary
        %   2 - Per-iteration update + solver summary
        %   
        %   Default: 0
        VerbosityLevel = 0

        %TrustRegionStrategyType The trust region step computation algorithm
        %   0 - Levenberg Marquardt
        %   1 - Dogleg
        %
        %   Default: 1
        TrustRegionStrategyType = 1

        %StateCovarianceType Estimate state covariances
        %   'none'           - No covariance estimation 
        %   'all-types'      - Enable covariance estimation for all nodes
        %   'POSE_SE2'       - Enable covariance estimation for 
        %                      POSE_SE2 node
        %   'POSE_SE3'       - Enable covariance estimation for 
        %                      POSE_SE3 node
        %   'POINT_XY'       - Enable covariance estimation for 
        %                      POINT_XY node
        %   'POINT_XYZ'      - Enable covariance estimation for 
        %                      POINT_XYZ node
        %   'IMU_BIAS'       - Enable covariance estimation for 
        %                      IMU_BIAS node
        %   'VEL3'           - Enable covariance estimation for VEL3 node
        %   'POSE_SE3_SCALE' - Enable covariance estimation for
        %                      POSE_SE3_SCALE node
        %   'TRANSFORM_SE3' - Enable covariance estimation for
        %                     TRANSFORM_SE3 node
        %
        %   Default: 'none'
        StateCovarianceType = nav.algs.internal.NodeTypeEnum.None

        %InitialTrustRegionRadius Initial trust region radius
        %
        %   Default: 1e4
        InitialTrustRegionRadius = 1e4
    end
    
    methods
        function obj = factorGraphSolverOptions(varargin)
            %FACTORGRAPHSOLVEROPTIONS Constructor
            obj = matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});
        end
        
        function obj = set.MaxIterations(obj, maxIter)
            %set.MaxIterations
            validateattributes(maxIter, 'numeric', ...
                {'scalar', 'integer', '>=', 1, 'nonsparse'}, 'factorGraphSolverOptions', 'MaxIteration');
            obj.MaxIterations = double(maxIter);
        end

        function obj = set.FunctionTolerance(obj, funTol)
            %set.MaxIterations
            validateattributes(funTol, 'numeric', ...
                {'scalar', 'real', 'finite','positive', 'nonsparse'}, 'factorGraphSolverOptions', 'FunctionTolerance');
            obj.FunctionTolerance = double(funTol);
        end

        function obj = set.GradientTolerance(obj, gradTol)
            %set.GradientTolerance
            validateattributes(gradTol, 'numeric', ...
                {'scalar', 'real', 'finite','positive', 'nonsparse'}, 'factorGraphSolverOptions', 'GradientTolerance');
            obj.GradientTolerance = double(gradTol);
        end

        function obj = set.StepTolerance(obj, stepTol)
            %set.StepTolerance
            validateattributes(stepTol, 'numeric', ...
                {'scalar', 'real', 'finite','positive', 'nonsparse'}, 'factorGraphSolverOptions', 'StepTolerance');
            obj.StepTolerance = double(stepTol);
        end

        function obj = set.VerbosityLevel(obj, vbLevel)
            %set.TrustRegionStrategyType
            validateattributes(vbLevel, 'numeric', ...
                {'scalar', 'integer', '>=', 0, '<=', 2, 'nonsparse'}, 'factorGraphSolverOptions', 'VerbosityLevel');
            obj.VerbosityLevel = double(vbLevel);
        end

        function obj = set.TrustRegionStrategyType(obj, trType)
            %set.TrustRegionStrategyType
            validateattributes(trType, 'numeric', ...
                {'scalar', 'integer', '>=', 0, '<=', 1, 'nonsparse'}, 'factorGraphSolverOptions', 'TrustRegionStrategyType');
            obj.TrustRegionStrategyType = double(trType);
        end

        function obj = set.StateCovarianceType(obj, covType)
            %set.StateCovarianceTypes
            covLen = length(covType);
            % Convert string array to cell array
            covType = convertStringsToChars(covType);
            if iscellstr(covType)
                % Check for duplicate char vectors in the cell array.
                coder.internal.errorIf(length(unique(covType))<covLen,'nav:navalgs:factorgraph:NoDuplicateCovarianceTypes');
                % Multiple node types specified, so 'none' and 'all-types' cannot
                % be included
                covSum = repmat(nav.algs.internal.NodeTypeEnum.None,1,covLen);
                for i = 1:covLen
                    cov = validatestring(covType{i}, {'none', 'all-types', 'POSE_SE2', 'POSE_SE3', 'POINT_XY', 'POINT_XYZ', 'VEL3', 'IMU_BIAS', 'POSE_SE3_SCALE', 'TRANSFORM_SE3'},...
                        'factorGraphSolverOptions', 'CovarianceEstimation');
                    cov = getCovarianceType(obj,cov);
                    coder.internal.errorIf(cov == nav.algs.internal.NodeTypeEnum.All_Types || cov == nav.algs.internal.NodeTypeEnum.None,...
                    'nav:navalgs:factorgraph:InvalidCovarianceTypeCombination');
                    covSum(i) = cov;
                end
            else
                % char vector
                cov = validatestring(covType, {'none', 'all-types', 'POSE_SE2', 'POSE_SE3', 'POINT_XY', 'POINT_XYZ', 'VEL3', 'IMU_BIAS', 'POSE_SE3_SCALE', 'TRANSFORM_SE3'},...
                    'factorGraphSolverOptions', 'CovarianceEstimation');
                covSum = getCovarianceType(obj,cov);
            end
            obj.StateCovarianceType = covSum;
        end

        function obj = set.InitialTrustRegionRadius(obj, r)
            %set.InitialTrustRegionRadius
            validateattributes(r, 'numeric', ...
                {'scalar', 'real', 'finite','positive', 'nonsparse'}, 'factorGraphSolverOptions', 'InitialTrustRegionRadius');
            obj.InitialTrustRegionRadius = double(r);
        end
    end

    methods (Hidden)
        function S = toStruct(obj)
            S = struct("MaxNumIterations", obj.MaxIterations, ...
                        "FunctionTolerance", obj.FunctionTolerance, ...
                        "GradientTolerance", obj.GradientTolerance, ...
                        "StepTolerance", obj.StepTolerance, ...
                        "VerbosityLevel", obj.VerbosityLevel, ...
                        "TrustRegionStrategyType", obj.TrustRegionStrategyType, ...
                        "StateCovarianceTypes", int32(obj.StateCovarianceType), ...
                        "InitialTrustRegionRadius", obj.InitialTrustRegionRadius);
        end

        function covType = getCovarianceType(~, cov)
            covType = nav.algs.internal.NodeTypeEnum.None;
            switch cov
                case 'all-types'
                    covType = nav.algs.internal.NodeTypeEnum.All_Types;
                case 'POSE_SE2'
                    covType = nav.algs.internal.NodeTypeEnum.Pose_SE2;
                case 'POSE_SE3'
                    covType = nav.algs.internal.NodeTypeEnum.Pose_SE3;
                case 'POINT_XY'
                    covType = nav.algs.internal.NodeTypeEnum.Point_XY;
                case 'POINT_XYZ'
                    covType = nav.algs.internal.NodeTypeEnum.Point_XYZ;
                case 'VEL3'
                    covType = nav.algs.internal.NodeTypeEnum.Vel_3;
                case 'IMU_BIAS'
                    covType = nav.algs.internal.NodeTypeEnum.IMU_Bias;
                case 'POSE_SE3_SCALE'
                    covType = nav.algs.internal.NodeTypeEnum.Pose_SE3_Scale;
                case 'TRANSFORM_SE3'
                    covType = nav.algs.internal.NodeTypeEnum.Transform_SE3;
            end
        end
    end
end

