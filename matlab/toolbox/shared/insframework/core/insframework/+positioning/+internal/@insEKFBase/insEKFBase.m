classdef (Hidden) insEKFBase < handle & positioning.internal.EKF & ...
        positioning.internal.ContinuousEKFPredictor  & ...
        fusion.internal.PositioningHandleBase
%   This class is for internal use only. It may be removed in the future.
%INSEKFBASE Base class for insEKF


%   Copyright 2021-2022 The MathWorks, Inc.    
    %#codegen
    
    properties
        %State State of the extended Kalman filter
        %   Specify the state vector of the extended Kalman filter. The
        %   State is an N-element column vector where N is determined by
        %   the specific sensors and motion models used to construct the
        %   filter.
        State

        %StateCovariance State error covariance for the extended Kalman filter
        %   Specify the state error covariance matrix for the extended
        %   Kalman filter. The StateCovariance is an N-by-N array
        %   where N is determined by the specific sensors and motion models
        %   used to construct the filter.
        StateCovariance

        %AdditiveProcessNoise Process noise for the extended Kalman filter
        %   Specify the additive process noise matrix for the extended
        %   Kalman filter. The AdditiveProcessNoise is an N-by-N array
        %   where N is determined by the specific sensors and motion models
        %   used to construct the filter.
        AdditiveProcessNoise
    end
    properties (GetAccess = public, SetAccess = protected)
        %MotionModel Motion model used to design the extended Kalman filter
        %   The MotionModel property is the motion model object used to
        %   construct the filter. The MotionModel property is read-only.
        MotionModel

        %Sensors Sensors used to design the extended Kalman filter
        %   The Sensors property is a cell array of sensor objects
        %   used to construct the filter. The Sensors property is read-only.
        Sensors

        %SensorNames Names of sensors used to design the filter
        %   The SensorNames property is a cell array of character vectors
        %   of names of the sensors used to design the filter. Custom
        %   sensor names can be set using the INSOPTIONS object. The
        %   SensorNames property is read-only. The SensorNames property
        %   determines the required timetable variable names for the
        %   ESTIMATESTATES and TUNE functions.
        SensorNames

        %ReferenceFrame Reference frame used in the filter
        %   The ReferenceFrame property specifies the reference frame being
        %   used for the filter, either NED or ENU. The ReferenceFrame
        %   property is read-only and can be controlled through the
        %   INSOPTIONS object.
        ReferenceFrame 
    end
  
    % Compiler related properties
    properties (Access = protected)
        MotionModelStateInfo
        SensorStateInfo
        StateInfo
        ReferenceFrameObject
        NumStates
        DefaultNames
        StateCovFullInfo % for when a full submatrix needs setting
        StateCovDiagInfo % for when only the diagonal needs setting
        StateCovDiagIndices % Diagonal indices in StateCovariance. Used by statecovparts
        AlwaysRepairQuaternion  % has an orientation as a quaternion. Always repair it.
        SensorImplementsStateTransition % Does the sensor implement a user-written stateTransition function
        PrecomputedStateTransitionJacobian % A precomputed stateTransitionJacobian 
                                           % of all zeros for sensors which don't implement stateTransition
    end

    properties (Access = {?positioning.internal.insEKFBase, ?positioning.internal.INSModelShared})
        Options % options object used to construct
    end

    methods (Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {...
                'Sensors', ...
                'MotionModel', ...
                'ReferenceFrame', ...
                'MotionModelStateInfo', ...
                'SensorStateInfo', ...
                'StateInfo', ...
                'NumStates', ...
                'SensorNames', ...
                'DefaultNames', ...
                'StateCovFullInfo', ...
                'StateCovDiagInfo', ...
                'StateCovDiagIndices', ...
                'Options', ...
                'AlwaysRepairQuaternion', ...
                'SensorImplementsStateTransition', ...
                'PrecomputedStateTransitionJacobian'};
        end
    end
    
    % Sets
    methods
        function set.State(filt,v)
            validateattributes(v, {'double', 'single'}, ...
                {'column', 'numel', filt.NumStates, 'real'}, ...
                '', 'State'); %#ok<MCSUP> 
            filt.State = v;
        end
        function set.StateCovariance(filt,v)
            validateattributes(v, {'double', 'single'}, ...
                {'square', 'numel', (filt.NumStates).^2, 'real'}, ...
                '', 'StateCovariance'); %#ok<MCSUP> 
            filt.StateCovariance = v;
        end
        function set.AdditiveProcessNoise(filt,v)
            validateattributes(v, {'double', 'single'}, ...
                {'square', 'numel', (filt.NumStates).^2, 'real'}, ...
                '', 'AdditiveProcessNoise'); %#ok<MCSUP> 
            filt.AdditiveProcessNoise = v;
        end
    end

    % Public API
    methods 
        function obj = insEKFBase(varargin)
            [motion, sensors,opts] = insEKF.parse(varargin{:});
            compile(obj, motion, sensors, opts);
        end
        idx = stateinfo(filt, varargin)
        [state, statecov] = correct(filt, idx, meas, mNoise);
        [res, rescov] = residual(filt, sensor, meas, mNoise, varargin);
        [state, statecov] = fuse(filt, sensor, meas, mNoise, varargin);
        [state, statecov] = predict(filt, dt, varargin);
        s = stateparts(filt, varargin)
        c = statecovparts(filt, varargin)
        [poseEst, smEst] = estimateStates(filt, sensorData, mnoise)
        createTunerCostTemplate(filt);
        p = tunerCostFcnParam(filt);
        c = copy(filt);
        reset(filt);
    end
    
    methods (Access = protected)
        compile(obj, motionmodel, sensors, opts)
        x = getStateInfo(obj, funcname, arg1, arg2)
        idx = getSensorIndex(filt, sensor)
        [x, P, h, H, z, R] = parseCorrectInputs(filt, idx, meas, mNoise)
        [x, P, h, H, z, R] = parseFuseInputs(filt, sensor, meas, mNoise)
        state = repairQuaternion(filt, state)
        [state, statecov] = rtsSmooth(filt, state, statecov, timestamps)
        [xdot, dfdx] = computeStateDerivative(filt, dt, varargin);
    end

    methods (Hidden)
        initializeState(filt)
        initializeStateCovariance(filt)
    end
    
    methods (Static, Hidden)
        [sensors, motionmodel, opts] = parse(varargin);
        [foundMotion, foundOpts] = verifyAndDetermineForm(varargin)
        si = makeStateInfo(motionStateInfo, sensorStateInfo, sensorNames, onceStruct)
        [once, oncestates] = processOnceStates(cls, opts)
    end
    
    methods (Access = {?positioning.internal.insEKFBase,?positioning.internal.INSModelShared}) 
        f = getReferenceFrameObject(filt)
    end

    methods (Hidden, Static)
        % For tab completion
        choices = statesTabCompletion(filt,sensor)
    end

    methods (Access = private)
        function configureFromLoad(obj, s)
            % First set the NumStates property so setting the State and
            % StateCovariance don't cause warnings.
            obj.NumStates = s.NumStates;
            s = rmfield(s, 'NumStates');
            fn = fieldnames(s);

            % Update all properties
            for ii=1:numel(fn)
                obj.(fn{ii}) = s.(fn{ii});
            end
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            obj = insEKF;
            configureFromLoad(obj, s);
        end
    end
end
