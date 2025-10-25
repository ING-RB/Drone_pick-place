classdef polynomialTrajectory < matlab.System ...
        & matlab.system.mixin.FiniteSource ...
        & fusion.scenario.internal.mixin.PlatformTrajectory
%

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    properties
        SampleRate = 100;
    end
    properties(Nontunable)
        SamplesPerFrame = 1;
    end

    properties (Access = private)
        RotMats;
        Quaternions;
        GravitationalAcceleration = fusion.internal.ConstantValue.Gravity;
    end

    properties (SetAccess = private, Dependent)
        Orientation;
    end

    properties (SetAccess = private)
        Waypoints;

        TimeOfArrival;

        AutoPitch = false;

        AutoBank = false;

        ReferenceFrame = 'NED';

        Velocities;

        Course;

        GroundSpeed;

        ClimbRate;
    end

    properties (Constant, Hidden)
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end

    properties (Nontunable, Access = private)
        IsOrientationSpecified = false;

        IsOrientationQuaternion = true;
    end

    properties (Access = private)
        SegmentTimes;
        RadianSlewAngles;
        AxesOfRotation;
        RadianAngularVelocities;

        CurrentTime;
        IsDoneStatus;

        PolynomialOrientation
    end

    properties(SetAccess = private, GetAccess = {?uav.scenarioapp.internal.shared.model.PolynomialTrajectorySpecification})
        TrajPiecewisePolynomial

        TrajDerivPiecewisePolynomial
    end

    properties (Hidden, SetAccess = protected)
        CurrentPosition
        CurrentVelocity
        CurrentAcceleration
        CurrentOrientation
        CurrentAngularVelocity
        CurrentPoseValid = false
    end

    methods
        function obj = polynomialTrajectory(varargin)
            setProperties(obj, varargin{:});

            % Set waypoints and orientation params
            setupInterpolants(obj);

            obj.CurrentTime = 0;
            setCurrentPose(obj, 0);
            obj.IsDoneStatus = false;
        end

        function [position, orientation, velocity, acceleration, angularVelocity] = lookupPose(obj, sampleTimes)
            validateattributes(sampleTimes,{'double'},{'real','vector','nonnegative'},'','SAMPTIMES');
            [position, orientation, velocity, acceleration, angularVelocity] = getPoses(obj, sampleTimes(:));
        end

        function set.SampleRate(obj, val)
            validateattributes(val, {'double'}, ...
                               {'real','finite','positive','scalar'}, ...
                               '', ...
                               'SampleRate');
            obj.SampleRate = val;
        end

        function set.SamplesPerFrame(obj, val)
            validateattributes(val, {'double'}, ...
                               {'real','finite','positive','scalar','integer'}, ...
                               '', ...
                               'SamplesPerFrame');
            obj.SamplesPerFrame = val;
        end

        function val = get.Orientation(obj)
            if obj.IsOrientationQuaternion
                val = obj.Quaternions;
            else
                val = obj.RotMats;
            end
        end
    end

    methods (Access = protected)
        function setProperties(obj, varargin)
            switch numel(varargin)
              case 0
                setWaypoints(obj, [0 0 0; 0 0 0]);
                setTimeOfArrival(obj, [0; 1]);
                breaks = [0,1];
                coefs = zeros(3);
                pp = mkpp(breaks, coefs, 3);
                setPiecewisePolynomials(obj, pp);
              otherwise
                obj.setTypeAndParams(varargin{:});
            end
            obj.PolynomialOrientation = fusion.scenario.internal.PolynomialTrajectoryOrientation(obj.TrajPiecewisePolynomial);
        end

        function setTypeAndParams(obj, varargin)
            pp = varargin{1};
            setPiecewisePolynomials(obj, pp);

            if ~isempty(obj.TrajPiecewisePolynomial)
                allParams = {'SamplesPerFrame', 'SampleRate', 'Orientation', 'AutoPitch', 'AutoBank', 'ReferenceFrame'};
                paramInput = {varargin{2:end}};

                pstruct = coder.internal.parseParameterInputs(allParams, [], paramInput{:});

                % Set time of arrival inferred from piecewise polynomial
                % breaks
                % Removed logical indexing to fix sigsegv failure
                % in codegen
                breaks = obj.TrajPiecewisePolynomial.breaks;
                idx = breaks(1,:)>=0;
                toa = breaks(1,idx);
                setTimeOfArrival(obj, toa);

                % Set SamplePerFrame property
                spf = coder.internal.getParameterValue(pstruct.SamplesPerFrame, 1, paramInput{:});
                obj.SamplesPerFrame = spf(:);

                % Set SampleRate property
                sampleRate = coder.internal.getParameterValue(pstruct.SampleRate, 100, paramInput{:});
                obj.SampleRate = sampleRate;

                % Set Orientation if defined
                orientation = coder.internal.getParameterValue(pstruct.Orientation, [], paramInput{:});
                if ~isempty(orientation)
                    setOrientation(obj, orientation);
                    obj.IsOrientationSpecified = true;
                    validateOrientationSizes(obj);
                end

                % Set Autopitch flag if user-defined
                autopitch = coder.internal.getParameterValue(pstruct.AutoPitch, false, paramInput{:});
                if pstruct.AutoPitch
                    setAutoPitch(obj, autopitch);
                end

                % Set AutoBank flag if user-defined
                autobank = coder.internal.getParameterValue(pstruct.AutoBank, false, paramInput{:});
                if pstruct.AutoBank
                    setAutoBank(obj, autobank);
                end

                % Set the ReferenceFrame property if defined
                referenceframe = coder.internal.getParameterValue(pstruct.ReferenceFrame, "NED", paramInput{:});
                setReferenceFrame(obj, referenceframe);
            end

        end

        function setPiecewisePolynomials(obj, pp)
            validateattributes(pp, {'struct'}, {'scalar'}, ...
                               '', 'ppstruct');
            if ~isempty(unmkpp(pp))
                validateattributes(pp.breaks, {'numeric'}, {'real', 'finite', 'vector'}, ...
                                   '', 'ppstruct.breaks');
                validateattributes(pp.coefs, {'numeric'}, {'real', 'finite'}, ...
                                   '', 'ppstruct.coefs');
                obj.TrajPiecewisePolynomial = pp;
                obj.setupPP();
            else
                coder.internal.error('Incorrect PP form')
            end
        end

        function setWaypoints(obj, val)
            validateattributes(val, {'double'}, ...
                               {'ncols', 3, '2d', 'real', 'finite'}, ...
                               '', ...
                               'Waypoints');
            coder.internal.assert(size(val, 1) > 1, ...
                                  'shared_sensorsim_trajectories:waypointTrajectory:InsufficientWaypoints');

            obj.Waypoints = val;
        end

        function setTimeOfArrival(obj, val)
            validateattributes(val, ...
                               {'double'}, ...
                               {'finite', 'real', 'nonnegative', 'increasing', 'vector'}, ...
                               '', ...
                               'TimeOfArrival');
            % Ensure it is a column vector.
            obj.TimeOfArrival = val(:);
        end

        function setGroundSpeed(obj, val)
            validateattributes(val, ...
                               {'double'}, ...
                               {'finite', 'real', 'vector'}, ...
                               '', ...
                               'GroundSpeed');
            dir = sign(val);
            if any(dir(1:end-1)==-dir(2:end) & dir(1:end-1) ~= 0)
                coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:InvalidGroundSpeedSignChange')
            end
            obj.GroundSpeed = val(:);
        end

        function setClimbRate(obj, val)
            validateattributes(val, ...
                               {'double'}, ...
                               {'finite', 'real', 'vector'}, ...
                               '', ...
                               'ClimbRate');
            obj.ClimbRate = val(:);
        end

        function setVelocities(obj, val)
            validateattributes(val, ...
                               {'double'}, ...
                               {'ncols', 3, '2d', 'real', 'finite'}, ...
                               '', ...
                               'Velocities');
            obj.Velocities = val;
            obj.CurrentPoseValid = false;
        end

        function setCourse(obj, val)
            validateattributes(val, ...
                               {'double'}, ...
                               {'vector', 'real'}, ...
                               '', ...
                               'Course');
            obj.Course = val(:);
            obj.CurrentPoseValid = false;
        end

        function setOrientation(obj, val)
            coder.internal.errorIf(obj.AutoBank, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoBank');
            coder.internal.errorIf(obj.AutoPitch, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoPitch');
            isQuat = isa(val, 'quaternion');
            if isQuat
                validateattributes(parts(val), ...
                                   {'double'}, ...
                                   {'ncols', 1, '2d'}, ...
                                   '', ...
                                   'Orientation');
                validateattributes(compact(val), ...
                                   {'double'}, ...
                                   {'real', 'finite'}, ...
                                   '', ...
                                   'Orientation');
                obj.Quaternions = val;
                obj.RotMats = rotmat(val, 'frame');
            else
                validateattributes(val, ...
                                   {'double'}, ...
                                   {'real','finite', 'size', [3 3 NaN]}, ...
                                   '', ...
                                   'Orientation');
                obj.Quaternions = quaternion(val, 'rotmat', 'frame');
                obj.RotMats = val;
            end
            obj.IsOrientationQuaternion = isQuat;
            obj.CurrentPoseValid = false;
        end

        function setAutoPitch(obj, val)
            coder.internal.errorIf(obj.IsOrientationSpecified, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoPitch');
            validateattributes(val,{'logical'},{'scalar'},'','AutoPitch');
            obj.AutoPitch = val;
            obj.CurrentPoseValid = false;
        end

        function setAutoBank(obj, val)
            coder.internal.errorIf(obj.IsOrientationSpecified, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoBank');
            validateattributes(val,{'logical'},{'scalar'},'','AutoBank');
            obj.AutoBank = val;
            obj.CurrentPoseValid = false;
        end

        function setReferenceFrame(obj, val)
            obj.ReferenceFrame = val;
        end

        function validateOrientationSizes(obj)

            n = numel(obj.TimeOfArrival);

            if obj.IsOrientationSpecified
                if obj.IsOrientationQuaternion
                    validateattributes(parts(obj.Quaternions), ...
                                       {'double'}, ...
                                       {'nrows', n}, ...
                                       '', ...
                                       'Orientation');
                else
                    validateattributes(obj.RotMats, ...
                                       {'double'}, ...
                                       {'size', [NaN NaN n]}, ...
                                       '', ...
                                       'Orientation');
                end
            end
        end

        function setupImpl(obj)
            obj.CurrentTime = 0;
            setCurrentPose(obj, 0);
            obj.IsDoneStatus = false;
        end

        function resetImpl(obj)
            obj.CurrentTime = 0;
            setCurrentPose(obj, 0);
            obj.IsDoneStatus = false;
        end

        function [position, orientation, velocity, acceleration, angularVelocity] = stepImpl(obj)
            t = obj.CurrentTime;
            dt = 1/obj.SampleRate;

            spf = obj.SamplesPerFrame;

            position = zeros(spf, 3);
            velocity = zeros(spf, 3);
            angularVelocity = zeros(spf, 3);
            acceleration = zeros(spf, 3);
            q = quaternion.ones(spf, 1);

            if ~isDone(obj)
                % Vector of simulation times for the frame
                simTimes = t + (dt:dt:obj.SamplesPerFrame*dt);
                [position, q, velocity, angularVelocity, acceleration] = setCurrentPose(obj, simTimes);

                t = simTimes(end);

                if ~isDone(obj)
                    obj.CurrentTime = t;
                    if (t+dt) > obj.TimeOfArrival(end)
                        obj.IsDoneStatus = true;
                    end
                end
            else
                position = nan(spf,3);
                velocity = nan(spf,3);
                acceleration = nan(spf,3);
                q = nan * quaternion.ones(spf, 1);
                angularVelocity = nan(spf,3);

                obj.CurrentPosition = nan(1,3);
                obj.CurrentVelocity = nan(1,3);
                obj.CurrentAcceleration = nan(1,3);
                obj.CurrentAngularVelocity = nan(1,3);
                obj.CurrentOrientation = nan * quaternion.ones;
            end

            if obj.IsOrientationQuaternion
                orientation = q;
            else
                orientation = rotmat(q, 'frame');
            end
        end

        function status = isDoneImpl(obj)
            status = obj.IsDoneStatus;
        end

        function setupInterpolants(obj)
            setupOrientationInterpolant(obj);
            setupWaypointParams(obj);
            obj.CurrentPoseValid = true;
        end

        function setupOrientationInterpolant(obj)
            if obj.IsOrientationSpecified
                q = obj.Quaternions;
                t = obj.TimeOfArrival;
                wi = [0 0 0];
                wf = [0 0 0];
                maxit = 10;
                tol = 1e-9;
                [h,dtheta,e,w] = fusion.scenario.internal.quaternionC2fit(q,t,wi,wf,maxit,tol);

                % Save results.
                obj.SegmentTimes = h;
                obj.RadianSlewAngles = dtheta;
                obj.AxesOfRotation = e;
                obj.RadianAngularVelocities = w;
            end
        end

        function setupWaypointParams(obj)
            if ~isempty(obj.TrajPiecewisePolynomial)
                t = obj.TimeOfArrival;

                waypoints = ppval(obj.TrajPiecewisePolynomial, t);
                setWaypoints(obj, pagetranspose(waypoints));

                if ~obj.IsOrientationSpecified
                    [~, orientation] = getPoses(obj, t);
                    obj.Quaternions = orientation;
                    obj.RotMats = rotmat(orientation,'frame');
                end

                if ~isempty(obj.TrajDerivPiecewisePolynomial)
                    velocities = ppval(obj.TrajDerivPiecewisePolynomial{1}, t);
                    obj.Velocities = velocities';
                end

                if ~isempty(obj.Velocities)
                    gndspeed = vecnorm(obj.Velocities(:, 1:2), 2, 2);
                    obj.GroundSpeed = gndspeed;

                    velocity = obj.Velocities;
                    if strcmp(obj.ReferenceFrame,'NED')
                        obj.ClimbRate = -velocity(:,3);
                    else
                        obj.ClimbRate = velocity(:,3);
                    end

                    obj.calculateCourse();

                end
            end
        end

        function calculateCourse(obj)
            if ~obj.IsOrientationSpecified
                %If orientation is NOT user-defined, then use the yaw from
                %obj.Quaternions as these values are calculated from the
                %velocity
                eulOrientation = eulerd(obj.Quaternions, 'ZYX', 'frame');
                obj.Course = eulOrientation(:,1);
            else
                %If the orientation is user-defined, then calculate the
                %Course from the velocity at the waypoints.
                if strcmp(obj.ReferenceFrame,'NED')
                    g = [ 0 0 obj.GravitationalAcceleration];
                else
                    g = [ 0 0 -obj.GravitationalAcceleration];
                end

                orientation = obj.PolynomialOrientation.getOrientationFromPolynomial( ...
                    obj.TimeOfArrival, false, false, g);

                eulOrientation = eulerd(orientation, 'ZYX', 'frame');
                obj.Course = eulOrientation(:,1);
            end
        end

        function [position, orientation, velocity, acceleration, angularVelocity, jerk] = getPoses(obj, simulationTimes)
            n = length(simulationTimes);

            ivalid = find(obj.TimeOfArrival(1) <= simulationTimes & simulationTimes <= obj.TimeOfArrival(end));
            position = nan(n,3);
            velocity = nan(n,3);
            acceleration = nan(n,3);
            jerk = nan(n,3);

            orientation = nan * quaternion.ones(n,1);
            angularVelocity = nan(n,3);

            if ~isempty(ivalid) && ~isempty(obj.TrajPiecewisePolynomial)
                % Evaluate piecewise polynomials for position, velocity,
                % acceleration and jerk
                position(ivalid, :) = pagetranspose(ppval(obj.TrajPiecewisePolynomial, simulationTimes(ivalid)));
                velocity(ivalid, :) = pagetranspose(ppval(obj.TrajDerivPiecewisePolynomial{1}, simulationTimes(ivalid)));
                acceleration(ivalid, :) = pagetranspose(ppval(obj.TrajDerivPiecewisePolynomial{2}, simulationTimes(ivalid)));
                if length(obj.TrajDerivPiecewisePolynomial) > 2
                    jerk(ivalid, :) = pagetranspose(ppval(obj.TrajDerivPiecewisePolynomial{3}, simulationTimes(ivalid)));
                else
                    jerk(ivalid, :) = [0, 0, 0];
                end

                if ~obj.IsOrientationSpecified
                    if strcmp(obj.ReferenceFrame,'NED')
                        g = [ 0 0 obj.GravitationalAcceleration];
                    else
                        g = [ 0 0 -obj.GravitationalAcceleration];
                    end

                    %getOrientationFromPolynomial method of the fusion.scenario.internal.PolynomialTrajectoryOrientation class
                    %calculates the orientation from the trajectory
                    %polynomial. This method uses the roots of the velocity
                    %to provide a continuous orientation within some
                    %thresholds.
                    [orientation, angularVelocity] = obj.PolynomialOrientation.getOrientationFromPolynomial( ...
                        simulationTimes(ivalid), obj.AutoPitch, obj.AutoBank, g);
                else
                    [orientation, angularVelocity] = fetchOrientationFromQuaternions(obj, simulationTimes(:));
                end
            end
        end

        function [position, orientation, velocity, angularVelocity, acceleration, jerk] = setCurrentPose(obj, simulationTime)

            [position, orientation, velocity, acceleration, angularVelocity, jerk] = getPoses(obj, simulationTime);

            % Set current pose values
            obj.CurrentPosition = position(end,:);
            obj.CurrentVelocity = velocity(end,:);
            obj.CurrentAcceleration = acceleration(end,:);
            obj.CurrentAngularVelocity = angularVelocity(end, :);
            obj.CurrentOrientation = orientation(end);
        end

        function [q, radianAngularVelocity] = fetchOrientationFromQuaternions(obj,t)
            y = obj.Quaternions;
            h = obj.SegmentTimes;
            dtheta = obj.RadianSlewAngles;
            e = obj.AxesOfRotation;
            w = obj.RadianAngularVelocities;
            x = obj.TimeOfArrival;

            [q, angularVelocityBodyFrame] = fusion.scenario.internal.getOrientationState(t, x, y, h, dtheta, e, w);
            m = rotmat(q, 'frame');
            radianAngularVelocity = angularVelocityBodyFrame;
            for i=1:length(q)
                radianAngularVelocity(i,:) = angularVelocityBodyFrame(i,:)*m(:,:,i);
            end
        end

        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);

            % Save private properties created during construction.
            s.Waypoints = obj.Waypoints;
            s.TimeOfArrival = obj.TimeOfArrival;
            s.Velocities = obj.Velocities;
            s.RotMats = obj.RotMats;
            s.Quaternions = obj.Quaternions;

            s.TrajPiecewisePolynomial = obj.TrajPiecewisePolynomial;
            s.TrajDerivPiecewisePolynomial = obj.TrajDerivPiecewisePolynomial;

            s.ReferenceFrame = obj.ReferenceFrame;
            s.AutoBank = obj.AutoBank;
            s.AutoPitch = obj.AutoPitch;
            s.GroundSpeed = obj.GroundSpeed;
            s.ClimbRate = obj.ClimbRate;
            s.Course = obj.Course;

            s.IsOrientationSpecified = obj.IsOrientationSpecified;
            s.IsOrientationQuaternion = obj.IsOrientationQuaternion;

            s.SegmentTimes = obj.SegmentTimes;
            s.RadianSlewAngles = obj.RadianSlewAngles;
            s.AxesOfRotation = obj.AxesOfRotation;
            s.RadianAngularVelocities = obj.RadianAngularVelocities;

            s.CurrentTime = obj.CurrentTime;
            s.IsDoneStatus = obj.IsDoneStatus;

            s.CurrentPosition = obj.CurrentPosition;
            s.CurrentVelocity = obj.CurrentVelocity;
            s.CurrentAcceleration = obj.CurrentAcceleration;
            s.CurrentOrientation = obj.CurrentOrientation;
            s.CurrentAngularVelocity = obj.CurrentAngularVelocity;
            s.CurrentPoseValid = obj.CurrentPoseValid;

            s.PolynomialOrientation = obj.PolynomialOrientation;
        end

        function loadObjectImpl(obj, s, wasLocked)
            loadObjectImpl@matlab.System(obj, s, wasLocked);

            % Load private properties created during construction.
            obj.Waypoints = s.Waypoints;
            obj.TimeOfArrival = s.TimeOfArrival;
            obj.Velocities = s.Velocities;
            obj.RotMats = s.RotMats;
            obj.Quaternions = s.Quaternions;

            obj.TrajPiecewisePolynomial = s.TrajPiecewisePolynomial;
            obj.TrajDerivPiecewisePolynomial = s.TrajDerivPiecewisePolynomial;

            obj.ReferenceFrame = s.ReferenceFrame;
            obj.AutoBank = s.AutoBank;
            obj.AutoPitch = s.AutoPitch;
            obj.GroundSpeed = s.GroundSpeed;
            obj.ClimbRate = s.ClimbRate;
            obj.Course = s.Course;

            obj.IsOrientationSpecified = s.IsOrientationSpecified;
            obj.IsOrientationQuaternion = s.IsOrientationQuaternion;

            obj.SegmentTimes = s.SegmentTimes;
            obj.RadianSlewAngles = s.RadianSlewAngles;
            obj.AxesOfRotation = s.AxesOfRotation;
            obj.RadianAngularVelocities = s.RadianAngularVelocities;

            obj.CurrentTime = s.CurrentTime;
            obj.IsDoneStatus = s.IsDoneStatus;

            obj.CurrentPosition = s.CurrentPosition;
            obj.CurrentVelocity = s.CurrentVelocity;
            obj.CurrentAcceleration = s.CurrentAcceleration;
            obj.CurrentOrientation = s.CurrentOrientation;
            obj.CurrentAngularVelocity = s.CurrentAngularVelocity;
            obj.CurrentPoseValid = s.CurrentPoseValid;

            %Init the PolynomialOrientation handle when loading earlier
            %versions of polynomialTrajectory
            if isfield(s, 'PolynomialOrientation')
                obj.PolynomialOrientation = s.PolynomialOrientation;
            else
                obj.PolynomialOrientation = fusion.scenario.internal.PolynomialTrajectoryOrientation(obj.TrajPiecewisePolynomial);
                
                %Set the new values of orientation
                [~, orientation] = getPoses(obj, obj.TimeOfArrival);
                obj.Quaternions = orientation;
                obj.RotMats = rotmat(orientation,'frame');

                %Calculate the new course values
                obj.calculateCourse();
            end
        end
    end

    % methods for platform trajectories
    methods (Hidden)
        function restart(obj)
            reset(obj);
        end

        function initTrajectory(obj)
            release(obj);
            obj.SamplesPerFrame = 1;
            setup(obj);
        end

        function initUpdateRate(obj, newUpdateRate)
            if obj.SampleRate ~= newUpdateRate
                obj.SampleRate = newUpdateRate;
            end
            if obj.SamplesPerFrame ~= 1
                release(obj);
                obj.SamplesPerFrame = 1;
            end
        end

        function status = move(obj, ~)
            status = ~obj.IsDoneStatus;
            step(obj);
        end

        function time = trajectoryLifetime(obj)
            time = obj.TimeOfArrival(end);
        end

        function time = startTime(obj)
            time = obj.TimeOfArrival(1);
        end

        function time = stopTime(obj)
            time = obj.TimeOfArrival(end);
        end
    end

    % debug methods
    methods (Hidden)
        function wpTable = waypointInfo(obj)
            valsCell = {obj.TimeOfArrival, obj.Waypoints};
            varsCell = {'TimeOfArrival', 'Waypoints'};

            if obj.IsOrientationSpecified
                orient = obj.Orientation;
                if ~obj.IsOrientationQuaternion
                    for i = size(orient, 3):-1:1
                        orientCell{i,:} = orient(:,:,i);
                    end
                else
                    for i = size(orient, 1):-1:1
                        orientCell{i,:} = orient(i,:);
                    end
                end
                valsCell{end+1} = orientCell;
                varsCell{end+1} = 'Orientation';
            end
            wpTable = table(valsCell{:}, 'VariableNames', varsCell);
        end
    end

    methods(Static, Hidden)
        function flag = isAllowedInSystemBlock
        % This System objects does not allow block creation in simulink
            flag = false;
        end
    end

    methods (Access = private)
        function setupPP(obj)
            pp = obj.TrajPiecewisePolynomial;
            obj.TrajDerivPiecewisePolynomial = cell(3,1);

            %Initializing cell content for MATLAB coder
            for i=1:3
                obj.TrajDerivPiecewisePolynomial{i} = pp;
            end

            obj.TrajDerivPiecewisePolynomial{1} = obj.derivpp(pp);
            obj.TrajDerivPiecewisePolynomial{2} = obj.derivpp(obj.TrajDerivPiecewisePolynomial{1});
            obj.TrajDerivPiecewisePolynomial{3} = obj.derivpp(obj.TrajDerivPiecewisePolynomial{2});
        end

        function dpp = derivpp(~, pp)
            [breaks,coefs,npieces, order, dim] = unmkpp(pp);

            % take the derivative of each polynomial
            newCoefs = reshape(coefs(:), npieces*dim, order);
            newCoefs = repmat([0, order-1:-1:1],dim*npieces,1).*circshift(newCoefs, 1, 2);
            dpp = mkpp(breaks,newCoefs,dim);
        end
    end
end
