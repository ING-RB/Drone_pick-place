classdef bicycleKinematics < robotics.mobile.internal.InternalAccess
%BICYCLEKINEMATICS Create bicycle vehicle model
%   BICYCLEKINEMATICS creates a bicycle vehicle model to simulate
%   simplified car-like vehicle dynamics. This model represents a
%   vehicle with two axles defined by the length between the axles,
%   WHEELBASE, and the wheel radius, WHEELRADIUS. The front wheel can
%   be turned with steering angle PHI. The vehicle heading THETA is
%   defined at the center of the rear axle.
%
%   OBJ = bicycleKinematics creates a bicycle kinematic model object
%   with default property values.
%
%   OBJ = bicycleKinematics('PropertyName', PropertyValue, ...) sets
%   properties on the object to the specified value. You can specify
%   multiple properties in any order.
%
%   BICYCLEKINEMATICS Properties:
%      WheelBase           - Distance between front and rear axles
%      VehicleSpeedRange   - Range of vehicle speeds
%      MaxSteeringAngle    - Maximum steering angle
%      MinTurningRadius    - Minimum vehicle turning radius (read-only)
%      VehicleInputs       - Type of command inputs with options:
%         "VehicleSpeedSteeringAngle"   - (Default) Vehicle speed and steering angle
%         "VehicleSpeedHeadingRate"     - Vehicle speed and heading angular velocity
%
%   BICYCLEKINEMATICS Methods:
%      derivative          - Time derivative of the vehicle state
%      copy                - Create a copy of the object
%
%   Example:
%      % Define robot and initial conditions
%      obj = bicycleKinematics;
%      initialState = [0 0 0];
%
%      % Set up simulation
%      tspan = 0:0.1:1;
%      inputs = [2 pi/4]; %Turn left
%      [t,y] = ode45(@(t,y)derivative(obj, y, inputs), tspan, initialState);
%
%      % Plot resultant path
%      figure
%      plot(y(:,1),y(:,2))
%   See also ackermannKinematics, unicycleKinematics, differentialDriveKinematics

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %VehicleInputs - Type of model inputs
        %   The VehicleInputs property specifies the format of the model
        %   input commands when using the derivative function. The property
        %   has two valid options, specified as a string or character
        %   vector:
        %      "VehicleSpeedSteeringAngle"   - (Default) Vehicle speed and steering angle
        %      "VehicleSpeedHeadingRate"     - Vehicle speed and heading angular velocity
        VehicleInputs
    end

    properties

        %WheelBase - Distance between front and rear axles
        %   The wheel base refers to the distance between the front and
        %   rear vehicle axles, specified in meters.
        WheelBase

        %VehicleSpeedRange - Range of vehicle speeds
        %   The vehicle speed range is a two-element vector that provides
        %   the minimum and maximum vehicle speeds, [MinSpeed MaxSpeed],
        %   specified in m/s.
        VehicleSpeedRange

        %MaxSteeringAngle - Maximum steering angle
        %   The maximum steering angle, PSI, refers to the maximum amount
        %   the vehicle can be steered to the right or left, specified in
        %   radians. The default value pi/4 provides the vehicle with a
        %   turning radius of 1 m. This property is used to validate the
        %   user-provided state input.
        MaxSteeringAngle
    end

    properties (Dependent, SetAccess = private)
        %MinimumTurningRadius - Minimum vehicle turning radius
        %   This read-only property returns the minimum vehicle turning
        %   radius in meters. The minimum radius is computed from the wheel
        %   base and maximum steering angle and is defined as the distance
        %   from the center of the turn to the vehicle origin, which is
        %   defined at the center of the rear axle. When the max steering
        %   angle is set to pi/2, the robot can pivot directly about its
        %   origin, which implies a zero minimum turning radius.
        MinTurningRadius
    end

    properties (Constant, Access = protected)
        %VehicleInputsOptions - The set of user-facing options for the VehicleInputs Name-Value pair
        VehicleInputsOptions = {'VehicleSpeedSteeringAngle', 'VehicleSpeedHeadingRate'};

        %VehicleInputsInternalOptions -  The set of internal options for the internal implementation of the VehicleInputs property, VehicleInputsInternal
        %   To ensure that these functions can be called in Simulink
        %   without relying on dynamic memory allocation, this class uses
        %   strings of equivalent length to represent the vehicle options
        %   internally. Therefore this set of options fills the values of
        %   the strings with less than the maximum number of characters
        %   with the equivalent number of hyphens
        VehicleInputsInternalOptions = {'VehicleSpeedSteeringAngle', 'VehicleSpeedHeadingRate--'};

        VehicleInputsDefault = 'VehicleSpeedSteeringAngle';

        WheelBaseDefault = 1;

        VehicleSpeedRangeDefault = [-inf inf];

        MaxSteeringAngleDefault = pi/4;
    end

    properties (Hidden)
        %VehicleInputsInternal - Fixed-length strings for codegen compatibility
        %   To ensure that these functions can be called in Simulink
        %   without relying on dynamic memory allocation, this class uses
        %   strings of equivalent length to represent the vehicle options
        %   internally. These are applied in the VehicleInputs Set method.
        VehicleInputsInternal
    end

    methods
        function obj = bicycleKinematics(varargin)
        %BICYCLEKINEMATICS Constructor

        % Convert strings to chars
            charInputs = cell(1,nargin);
            [charInputs{:}] = convertStringsToChars(varargin{:});

            % Parse inputs
            names = {'WheelBase', 'VehicleSpeedRange', 'MaxSteeringAngle', 'VehicleInputs'};
            defaults = {obj.WheelBaseDefault, obj.VehicleSpeedRangeDefault, ...
                        obj.MaxSteeringAngleDefault, obj.VehicleInputsDefault};
            parser = robotics.core.internal.NameValueParser(names, defaults);
            parse(parser, charInputs{:});
            obj.WheelBase = parameterValue(parser, names{1});
            obj.VehicleSpeedRange = parameterValue(parser, names{2});
            obj.MaxSteeringAngle = parameterValue(parser, names{3});
            obj.VehicleInputs = parameterValue(parser, names{4});
        end

        function stateDot = derivative(obj, state, cmds)
        %DERIVATIVE Time derivative of model states
        %   STATEDOT = derivative(OBJ, STATE, CMDS) returns the current
        %   state derivative, STATEDOT, as a three-element vector [XDOT
        %   YDOT THETADOT]. XDOT and YDOT refer to the vehicle velocity
        %   in meters per second. THETADOT is the angular velocity of
        %   the vehicle heading in rad/s.
        %
        %      OBJ     - Bicycle vehicle model object
        %
        %      STATE   - A three-element state vector [X Y THETA] or [Nx3]
        %                matrix with each row representing the same state
        %                vector. Here, X and Y are the global vehicle
        %                position in meters, and THETA is the global vehicle
        %                heading in radians.
        %
        %      CMDS    - A two-element vector or an [Nx2] matrix of
        %                input commands. The format is dependent on the
        %                value of the VEHICLEINPUTS property of OBJ:
        %                   - "VehicleSpeedSteeringAngle": A two-element
        %                     vector or [Nx2] matrix of input commands
        %                     [V PSI], where V is the vehicle speed,
        %                     PSI is the  vehicle steering angle in
        %                     radians, and N is the number of time
        %                     instances.
        %                   - "VehicleSpeedHeadingRate": A two-element
        %                     vector or [Nx2] matrix of input commands
        %                     [V THETADOT], where V is the vehicle speed,
        %                     THETADOT is the rate of change of the
        %                     vehicle heading, THETA, in radians/s,
        %                     and N is the number of time instances.
        %
        %
        %   Example:
        %      % Define robot and initial conditions
        %      obj = bicycleKinematics;
        %      initialState = [0 0 0];
        %
        %      % Set up simulation
        %      tspan = 0:0.1:1;
        %      inputs = [2 pi/4]; %Turn left
        %      [t,y] = ode45(@(t,y)derivative(obj, y, inputs), tspan, initialState);
        %
        %      % Plot resultant path
        %      figure
        %      plot(y(:,1),y(:,2))

            narginchk(3,3);

            % Validate state
            if isvector(state)
                % Input state is a row or column vector
                validateattributes(state, {'double', 'single'}, {'nonempty', 'numel', 3, 'real', 'nonnan'}, 'derivative', 'state');

                % Vector input is of shape [1 x 3] or [3 x 1]
                stateReshaped = [state(1), state(2), state(3)];
            else
                % Input state is a [N,3] matrix
                validateattributes(state, {'double', 'single'}, {'nonempty', 'ncols', 3, 'real', 'nonnan'}, 'derivative', 'state');

                % Matrix input is always of shape [numState x 3]
                stateReshaped = state;
            end

            % Validate input commands
            if isvector(cmds)
                % Input commands is a row or column vector
                validateattributes(cmds, {'double', 'single'}, {'nonempty', 'numel', 2, 'real', 'finite'}, 'derivative', 'cmds');

                % Vector input is of shape [1 x 2] or [2 x 1]
                cmdsReshaped = [cmds(1), cmds(2)];
            else
                % Input commands is a [N,2] matrix
                validateattributes(cmds, {'double', 'single'}, {'nonempty', 'ncols', 2, 'real', 'finite'}, 'derivative', 'cmds');

                % Matrix input is always of shape [numCmds x 2]
                cmdsReshaped = cmds;
            end

            % validate numState is equal to numCmds
            if ~isvector(cmds) && ~isvector(state)
                validateattributes(cmds,{'double', 'single'},{'nrows', height(state)},'derivative','cmds')
            end

            % Compute state derivative
            stateDot = obj.derivativeImpl(stateReshaped, cmdsReshaped);
        end

        function newVehicle = copy(obj)
        %COPY Copy kinematic model
        %   NEWVEHICLE = COPY(VEHICLE) returns a deep copy of VEHICLE.
        %   NEWVEHICLE and VEHICLE are two different bicycleKinematics
        %   objects with the same properties.
        %
        %   Example:
        %       % Create a bicycle kinematic model
        %       b1 = bicycleKinematics('WheelBase', 2)
        %
        %       % Make a copy
        %       b2 = COPY(b1)

            newVehicle = bicycleKinematics(...
                'VehicleInputs', obj.VehicleInputs, ...
                'WheelBase', obj.WheelBase, ...
                'VehicleSpeedRange', obj.VehicleSpeedRange, ...
                'MaxSteeringAngle', obj.MaxSteeringAngle ...
                                          );
        end
    end

    %% Get/Set methods

    methods
        function set.WheelBase(obj, vehicleLength)
        %SET.WHEELBASE Setter method for WheelBase

            validateattributes(vehicleLength, {'double', 'single'}, {'nonempty', 'scalar', 'finite', 'positive'}, 'bicycleKinematics', 'WheelBase');
            obj.WheelBase = vehicleLength;
        end

        function set.VehicleSpeedRange(obj, speedRange)
        %SET.VEHICLESPEEDRANGE Setter method for VehicleSpeedRange

            validateattributes(speedRange, {'double', 'single'}, {'nonempty', 'vector', 'numel', 2, 'nonnan', 'nondecreasing'}, 'bicycleKinematics', 'VehicleSpeedRange');
            obj.VehicleSpeedRange = speedRange(:)';
        end

        function set.MaxSteeringAngle(obj, steeringAngle)
        %SET.MAXSTEERINGANGLE Setter method for MaxSteeringAngle

            validateattributes(steeringAngle, {'double', 'single'}, {'nonempty', 'scalar', 'finite', 'nonnegative'}, 'bicycleKinematics', 'MaxSteeringAngle');
            obj.MaxSteeringAngle = steeringAngle;
        end

        function set.VehicleInputs(obj, inputString)
        %SET.VEHICLEINPUTS Setter method for VehicleInputs

            vehicleInputs = validatestring(inputString, obj.VehicleInputsOptions, 'bicycleKinematics', 'VehicleInputs');

            % Inputs have to be the same length for code generation
            if strcmp(vehicleInputs, obj.VehicleInputsOptions{1})
                obj.VehicleInputsInternal = obj.VehicleInputsInternalOptions{1};
            else
                obj.VehicleInputsInternal = obj.VehicleInputsInternalOptions{2};
            end
        end

        function strValue = get.VehicleInputs(obj)
        %GET.VEHICLEINPUTS Getter method for VehicleInputs

        % Map the string back from the internal version
            if strcmp(obj.VehicleInputsInternal, obj.VehicleInputsInternalOptions{1})
                strValue = obj.VehicleInputsOptions{1};
            else
                strValue = obj.VehicleInputsOptions{2};
            end
        end

        function radius = get.MinTurningRadius(obj)
        %GET.MinTurningRadius Get method for maximum turning radius
        %   This method updates the minimum turning radius given the
        %   vehicle dimensions. The property cannot be directly set by
        %   the user.

            psi = min(obj.MaxSteeringAngle, pi/2);
            if psi == 0
                radius = Inf;
            else
                radius = obj.WheelBase*tan(pi/2-psi);
            end
        end
    end

    %% Helper methods

    methods (Access = protected)
        function [v, omega] = processInputs(obj, cmds)
        %processInputs Convert inputs to generalized form and acknowledge constraints
        %   This function takes in the inputs and produces v and omega,
        %   the generalized vehicle inputs. During the conversion, it
        %   checks that all input constraints are satisfied, and
        %   saturates them if that is not the case.

        % Velocity is shared between the two types of inputs
            v = cmds(:,1);

            % Saturate velocity if it exceeds vehicle speed range
            v = max(v, obj.VehicleSpeedRange(1));
            v = min(v, obj.VehicleSpeedRange(2));

            % Initialize outputs to ensure codegen compatibility
            numCmds = height(cmds);
            omega = zeros(numCmds, 1, 'like', cmds);

            % Saturate inputs and convert to generalized format
            switch obj.VehicleInputsInternal
              case 'VehicleSpeedSteeringAngle'
                % Saturate inputs
                [v(:), omega(:)] = getGeneralizedInputsFromModelInputs(obj, v, cmds(:,2));
              case 'VehicleSpeedHeadingRate--'
                [v, psi] = getWheelControlFromVehicleControl(obj, cmds(:,1), cmds(:,2));
                [v(:), omega(:)] = getGeneralizedInputsFromModelInputs(obj, v, psi);
            end
        end

        function [v, omega] = getGeneralizedInputsFromModelInputs(obj, v, psi)
        %getGeneralizedInputsFromModelInputs Convert inputs to from model to generalized form
        %   Convert the model specific inputs, v and psi for the
        %   bicycle, to the generalized vehicle inputs, v and omega.

        % Apply maximum steering angle
            aboveThreshold = abs(psi) > obj.MaxSteeringAngle;
            if any(aboveThreshold)
                psi(aboveThreshold) = sign(psi(aboveThreshold))*obj.MaxSteeringAngle;
            end

            % Convert steering angle to vehicle heading angular velocity.
            % This calculation is derived from the relationship v =
            % omega/R, where R is the turning radius, and tan(psi) = L/R,
            % where R is the wheel base.
            omega = (v/obj.WheelBase).*tan(psi);
        end

        function [v, psi] = getWheelControlFromVehicleControl(obj, v, omega)
        %getWheelControlFromVehicleControl Convert inputs to from generalized to model form
        %   Convert the generalized vehicle inputs, v and omega, to the
        %   model specific inputs, which are v and psi for the bicycle

        % Use atan2 to avoid problems when both v and omega tend to
        % zero.
            psi = atan2(omega*obj.WheelBase, v);

            % atan2 wraps the angle to lie between -pi and pi but the steering
            % angle can lie only in quadrant 1 and 4, between -pi/2 and
            % pi/2.
            isInSecondQuadrant = psi > pi/2;
            isInThirdQuadrant  = psi < -pi/2;
            if any(isInSecondQuadrant)
                psi(isInSecondQuadrant) = psi(isInSecondQuadrant) - pi; % psi is in 2nd quadrant. Subtract pi to shift to 4th quadrant
            end
            if any(isInThirdQuadrant)
                psi(isInThirdQuadrant ) = psi(isInThirdQuadrant ) + pi; % psi is in 3rd quadrant. Add pi to shift to 1st quadrant
            end
        end
    end

    methods(Access=?robotics.mobile.internal.InternalAccess)
        function stateDot = derivativeImpl(obj, state, cmds)
        %derivativeImpl Implementation of bicycle kinematics
        % Compute the derivative using either a single command or
        % multiple commands at a given initial state.
        %
        % INPUTS
        %   STATE   : Array of shape [1 x 3] or [N x 3]
        %   CMDS    : Array of [1 x 2] or [N x 2]
        % OUTPUTS
        %   STATEDOT: Array of shape [3 x N]

        % Process inputs
            [v, omega] = processInputs(obj, cmds);

            % Get States
            theta = state(:,3);

            % Compute state derivative
            numStates = height(state);
            J = zeros(3,2,numStates,'like',state);
            J(1,1,:) = cos(theta);
            J(2,1,:) = sin(theta);
            J(3,2,:) = 1;
            inp = reshape([v'; omega'],2,1, []);
            stateDot = pagemtimes(J, inp);
            stateDot = reshape(stateDot,3,[]);
        end
    end
end
