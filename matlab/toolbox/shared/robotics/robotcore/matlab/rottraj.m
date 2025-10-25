function [R, omega, alpha] = rottraj(R0, RF, timeInterval, t, varargin)
%ROTTRAJ Generate trajectory between two orientations
%   This function interpolates between two orientations R0 and RF,
%   specified as scalar quaternion objects, scalar so3 objects, 1x4
%   quaternion vectors, or 3x3 rotation matrices. The function outputs the
%   series of interpolated orientations in time returned as an Mx1
%   quaternion object array, an Mx1 so3 object array, a 4xM vector of
%   quaternions, or a 3x3xM matrix of rotation matrices. The format is
%   determined by the type of the first input. The function also outputs a
%   3xM vector of angular velocities (rad/s), OMEGA, and a 3xM vector of
%   angular accelerations (rad/s^2), ALPHA.
%
%   [R, omega, alpha] = rottraj( R0, RF, timeInterval, t)
%
%      R0 -             The initial orientation, specified as a scalar
%                       quaternion object, a scalar so3 object, a 1x4
%                       quaternion vector, or a 3x3 rotation matrix.
%
%      RF -             The final orientation, specified as a scalar
%                       quaternion object, a scalar so3 object, a 1x4
%                       quaternion vector, or a 3x3 rotation matrix.
%
%      TIMEINTERVAL -   A two element vector indicating the start and end
%                       time of the trajectory. The initial and final
%                       position are held constant outside this interval.
%
%      T -              An M-element time vector or instant in time at
%                       which the trajectory is evaluated
%
%   [R, omega, alpha] = rottraj(___, Name, Value) provides additional
%   options specified by the Name-Value pair arguments.
%
%      TIMESCALING -   The time scaling vector s(t) and its first two
%                      derivatives, ds/dt and d^2s/dt^2 defined as a 3xM
%                      vector [s; ds/dt; d^2s/dt^2]. In the default case, a
%                      linear time scaling is used:
%                      s(t) = C*t, sd(t) = C, sdd(t) = 0
%                      where C = 1/(timeInterval(2) - timeInterval(1)).
%
%   References:
%
%      1. Graf, Basile. "Quaternions and Dynamics." arXiv:0811.2889
%         [math.DS] (2008). https://arxiv.org/pdf/0811.2889.pdf
%
%      2. Dam, Erik B., Martin Koch, and Martin Lillholm. "Quaternions,
%         Interpolation and Animation". Technical Report DIKU-TR-98/5
%         (July 1998). http://web.mit.edu/2.998/www/QuaternionReport1.pdf
%
%   Example:
%      % Define time vector
%      tvec = 0:0.01:5;
%
%      % Define time over which rotation will occur
%      tpts = [1 4];
%
%      % Define two quaternion waypoints
%      q0 = quaternion([0 pi/4 -pi/8],'euler','ZYX','point');
%      qF = quaternion([3*pi/2 0 -3*pi/4],'euler','ZYX','point');
%
%      % Interpolate between the points
%      [qInterp1, w1, a1] = rottraj(q0, qF, tpts, tvec);
%
%      % Interpolate between the points using a cubic time scaling
%      [s, sd, sdd] = cubicpolytraj([0 1], tpts, tvec);
%      [qInterp2, w2, a2] = ...
%         rottraj(q0, qF, tpts, tvec, 'TimeScaling', [s; sd; sdd]);
%
%      % Compare outputs
%      figure
%      plot(tvec, compact(qInterp1))
%      legendText = 'Linear (Solid) vs. Cubic (Dashed)';
%      title(['Quaternion Interpolation Time Scaling: ' legendText])
%      hold on
%      plot(tvec, compact(qInterp2), '--')
%      hold off
%
%   See also transformtraj.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Ensure the correct number of inputs
    narginchk(4,6);
    % Convert strings to chars case by case for codegen support
    if nargin > 4
        charInputs = cell(1,2);
        [charInputs{:}] = convertStringsToChars(varargin{:});
    else
        charInputs = {};
    end

    % Default input checks
    q0 = validateRotationInput(R0, 'R0');
    qF = validateRotationInput(RF, 'RF');
    inputType = determineInputType(R0);
    validateattributes(timeInterval, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'rottraj','timeInterval');
    validateattributes(t, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'rottraj','t');

    % Setup dimensions
    m = length(t);

    % Parse inputs
    names = {'TimeScaling'};
    defaults = {robotics.core.internal.constructLinearTimeScaling(timeInterval, t)};
    parser = robotics.core.internal.NameValueParser(names, defaults);
    parse(parser, charInputs{:});
    timeScaling = parameterValue(parser, names{1});

    % Input checks
    timeScaling = robotics.core.internal.validateTimeScaling(timeScaling, m, 'rottraj');

    % Process time scaling
    s = timeScaling(1,:);
    sd = timeScaling(2,:);
    sdd = timeScaling(3,:);

    % Initialize outputs
    inputQuatClassUnderlying = classUnderlying(q0);
    omega = zeros(3,m,inputQuatClassUnderlying);
    alpha = zeros(3,m,inputQuatClassUnderlying);
    qCalc = ones(m,1,'like',q0);

    % Prep inputs
    pn = q0.normalize;
    qn = qF.normalize;

    % Get corrected start and end values from quaternion slerp method
    pnCorrected = slerp(pn,qn,0);
    qnCorrected = slerp(pn,qn,1);
    for i = 1:m
        qCalc(i) = slerp(pn,qn,s(i));

        % Compute angular velocity from the quaternion derivative:
        %    - omega = 2(dq/dt)(q*)
        qdCalc = computeFirstQuatDerivative(pnCorrected, qnCorrected, sd(i), qCalc(i));
        W = compact(2*qdCalc*conj(qCalc(i)));
        omega(:,i) = W(2:4);

        % Compute angular acceleration from the second quaternion time
        % derivative (can be found by differentiating the omega term above)
        %    - alpha = 2(d^2q/dt^2)(q*) - 2(dq/dt)d(q*)/dt
        qddCalc = computeSecondQuatDerivative(pnCorrected, qnCorrected, sd(i), sdd(i), qCalc(i));
        A = compact(2*qddCalc*conj(qCalc(i)) - 2*qdCalc*conj(qdCalc));
        alpha(:,i) = A(2:4);
    end

    switch inputType
      case 'quat'
        % Quaternion object
        R = qCalc;
      case 'so3'
        % Return as so3 object array
        R = so3(qCalc);
      case 'quatv'
        % Quaternion vector (numeric)
        R = compact(qCalc)';
      case 'rotm'
        % Rotation matrix (numeric)
        R = rotmat(qCalc,'point');
    end
end
%% Helper functions
function inputType = determineInputType(rotInput)
%determineInputType Determine input type for code generation
%   In order for coder to work with varying input-dependent output types,
%   the input type must be set via a method that is constant at
%   compile-time.
    switch size(rotInput,2)
      case 1
        if isa(rotInput, 'quaternion')
            % Quaternion object
            inputType = 'quat';
        else
            inputType = 'so3';
        end
      case 3
        % Rotation matrix
        inputType = 'rotm';
      case 4
        % Quaternion vector
        inputType = 'quatv';
    end
end
function q = validateRotationInput(rotInput, inputName)
%validateRotationInput Verify that rotation input is valid and convert to quaternion
    if isa(rotInput, 'quaternion') && isscalar(rotInput)
        %Scalar quaternion object
        q = rotInput;
    elseif isa(rotInput, 'so3') && isscalar(rotInput)
        %Scalar so3 object. Convert so3 matrix to quaternion
        q = quaternion(rotInput);
    elseif all(size(rotInput) == [1 4])
        %Vector representing a quaternion
        rotInput = robotics.internal.validation.validateQuaternion(rotInput, 'rottraj', inputName);
        q = quaternion(rotInput);
    elseif all(size(rotInput) == [3 3])
        %Verify that this is a valid rotation matrix and convert to quaternion
        robotics.internal.validation.validateRotationMatrix(rotInput, 'rottraj', inputName);
        q = quaternion(rotInput, 'rotmat', 'point');
    else
        coder.internal.errorIf(true, 'shared_robotics:robotcore:utils:RotTrajInvalidInput', inputName);
    end
end
function qdot = computeFirstQuatDerivative(pn, qn, sd, qinterp)
%computeFirstQuatDerivative Compute the instantaneous first derivative
%   This helper uses the analytical representation of the interpolation
%   method to compute the first derivative of the interpolation method at
%   an instant specified by the time derivative of the time scaling.
%      d(slerp)/dt = d(slerp)/ds ds/dt
%   The slerp derivative is derived in (2):
%      d(slerp)/ds = slerp(p,q,h)log(p* q)

    qdot = (qinterp*log((conj(pn)*qn)))*sd;

end

function qddot = computeSecondQuatDerivative(pn, qn, sd, sdd, qinterp)
%computeSecondQuatDerivative Compute the instantaneous second derivative
%   This helper uses the analytical representation of the interpolation
%   method to compute the second derivative of the interpolation method at
%   an instant specified by the second time derivative of the time scaling.
%      d(slerp)/dt^2
%      = d/dt(d(slerp)/dt)
%      = d/dt(d(slerp)/ds ds/dt) =
%      = (d^2(slerp)/ds^2 ds/dt)ds/dt + (d(slerp)/ds sddot)

% Compute d(slerp)/ds by computing d(slerp)/dt, s = t
    firstSlerpDerivative = computeFirstQuatDerivative(pn, qn, 1, qinterp);

    % The second derivative, d/(slerp)/ds^2 is defined in (2). Multiply the
    % log twice since there is no power law for quaternions.
    secondSlerpDerivative = (qinterp*log((conj(pn)*qn))*log((conj(pn)*qn)));

    qddot = secondSlerpDerivative*sd^2 + firstSlerpDerivative*sdd;

end
