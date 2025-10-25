classdef stateEstimatorPF < matlabshared.tracking.internal.ParticleFilter
%

%   The help text for this class is intentionally blank. It will be
%   loaded from the en/stateEstimatorPF.m file.

%   Copyright 2015-2019 The MathWorks, Inc.

%#codegen

    methods
        function obj = stateEstimatorPF()
            obj@matlabshared.tracking.internal.ParticleFilter();

            % stateEstimatorPF makes additional default assignments
            % than the current base class. These ensure backwards
            % compatibility with 2017a and prior

            % Initialize particle filter with default mean and covariance
            %
            % This also assigns default distributions
            obj.initialize(obj.defaultNumParticles, obj.defaultStateMean, obj.defaultStateCovariance, ...
                           'CircularVariables', obj.defaultIsStateVariableCircular, ...
                           'StateOrientation',  obj.defaultStateOrientation);

            % Set default callback functions
            % Do not initialize the properties for code generation, since
            % function handles can only be assigned once.
            if coder.target('MATLAB')
                obj.StateTransitionFcn = obj.defaultStateTransitionFcn;
                obj.MeasurementLikelihoodFcn = obj.defaultMeasurementLikelihoodFcn;
            end
        end
    end

    methods (Access = {?matlabshared.tracking.internal.ParticleFilter, ?matlab.unittest.TestCase})
        function numStateVariables = defaultNumStateVariables(~)
        %defaultNumStateVariables The default value for the NumStateVariables property
            numStateVariables = 3;
        end

        function numParticles = defaultNumParticles(~)
        %defaultNumParticles The default value for the NumParticles property
            numParticles = 1000;
        end

        function resamplePolicy = defaultResamplingPolicy(~)
        %defaultResamplingPolicy The object determining when resampling should occur
            resamplePolicy = resamplingPolicyPF;
        end

        function stateTransFcn = defaultStateTransitionFcn(~)
        %defaultStateTransitionFcn The default value for the StateTransitionFcn property
            stateTransFcn = @nav.algs.gaussianMotion;
        end

        function measLhoodFcn = defaultMeasurementLikelihoodFcn(~)
        %defaultMeasurementLikelihoodFcn The default value for the MeasurementLikelihoodFcn property
            measLhoodFcn = @nav.algs.fullStateMeasurement;
        end

        function isVarCircular = defaultIsStateVariableCircular(~)
        %defaultIsStateVariableCircular The default value for the IsStateVariableCircular property
            isVarCircular = false(1,3);
        end

        function stateMean = defaultStateMean(~)
        %defaultStateMean The initial state's mean value
        %   The default is a zero mean.
            stateMean = zeros(1,3);
        end

        function stateCov = defaultStateCovariance(~)
        %defaultStateCovariance The initial covariance around DefaultStateMean
        %   The default covariance is a variance of 1 for each state variable.
            stateCov = eye(3);
        end

        function stateOrientation = defaultStateOrientation(~)
        %defaultStateOrientation The default value for the StateOrientation property
            stateOrientation = 'row';
        end
    end

    methods (Access=protected)
        function predictParticles = invokeStateTransitionFcn(obj, varargin)
        %invokeStateTransitionFcn
        %
        % Invoke the user provided StateTransitionFcn with the expected syntax
            predictParticles = obj.StateTransitionFcn(obj, obj.Particles, varargin{:});
        end

        function lhood = invokeMeasurementLikelihoodFcn(obj, measurement, varargin)
        %invokeMeasurementLikelihoodFcn
        %
        % Invoke the user provided MeasurementLikelihoodFcn with the expected syntax
            lhood = obj.MeasurementLikelihoodFcn(obj, obj.Particles, measurement, varargin{:});
        end
    end
end
