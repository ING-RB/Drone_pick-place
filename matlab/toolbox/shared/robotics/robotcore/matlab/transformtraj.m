function [tform, vel, acc] = transformtraj(T0, TF, timeInterval, t, varargin)
%TRANSFORMTRAJ Generate trajectory between two homogeneous transforms
%   This function interpolates between two transformations T0 and TF,
%   specified as scalar se3 objects, or 4x4 homogeneous transformation
%   matrices, given a 1xM time vector T from zero to one. The function
%   returns an Mx1 se3 object array, or a 4x4xM array of transformations
%   TFORM (position elements in m), as well as a 6xM matrix VEL of the
%   angular velocities (rad/s) and velocities (m/s) in time, and a 6xM
%   matrix ACC of the angular accelerations (rad/s^2) and accelerations
%   (m/s^2) in time.
%
%   [T, V, A] = transformtraj(T0, TF, timeInterval, t)
%
%      T0 -             A scalar se3 object or a 4x4 homogeneous
%                       transformation matrix specifying
%                       the initial position and orientation
%
%      TF -             A scalar se3 object or a 4x4 homogeneous
%                       transformation matrix specifying
%                       the final position and orientation
%
%      TIMEINTERVAL -   A two element vector indicating the start and end
%                       time of the trajectory. The initial and final
%                       position are held constant outside this interval.
%
%      T -              An M-element vector or instant in time at which the
%                       trajectory is evaluated
%
%   [TFORM, VEL, ACC] = transformtraj(___, Name, Value) provides additional
%   options specified by the Name-Value pair arguments.
%
%      TIMESCALING -   The time scaling vector s(t) and its first two
%                      derivatives, ds/dt and d^2s/dt^2 defined as a 3xM
%                      vector [s; ds/dt; d^2s/dt^2]. In the default case, a
%                      linear time scaling is used:
%                      s(t) = C*t, sd(t) = C, sdd(t) = 0
%                      where C = 1/(timeInterval(2) - timeInterval(1)).
%
%   Example:
%      % Define time vector
%      tvec = 0:0.01:5;
%
%      % Define time over which rotation will occur
%      tpts = [1 4];
%
%      % Build transforms from two orientations and positions
%      T0 = axang2tform([0 1 1 pi/4]);
%      TF = axang2tform([1 0 1 6*pi/5]);
%      TF(1:3,4) = [1 -5 23]';
%
%      % Interpolate between the points
%      [tfInterp1, v1, a1] = transformtraj(T0, TF, tpts, tvec);
%
%      % Interpolate between the points using a cubic time scaling
%      [s, sd, sdd] = minjerkpolytraj([0 1], tpts, numel(tvec));
%      [tfInterp2, v2, a2] = ...
%         transformtraj(T0, TF, tpts, tvec, 'TimeScaling', [s; sd; sdd]);
%
%      % Compare the position interpolation
%      figure
%      plot(tvec, reshape(tfInterp1(1:3,4,:),3,size(tfInterp1,3)))
%      title('Linear (Solid) vs Min Jerk (Dashed) Position Time Scaling')
%      hold on
%      plot(tvec, reshape(tfInterp2(1:3,4,:),3,size(tfInterp1,3)), '--')
%      hold off
%
%   See also rottraj.

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
    tform0 = validateTransformationInput(T0, 'T0');
    tformF = validateTransformationInput(TF, 'TF');
    inputType = determineInputType(T0);
    validateattributes(timeInterval, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'transformtraj','timeInterval');
    validateattributes(t, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'transformtraj','t');

    % Setup dimensions
    m = length(t);

    % Parse inputs
    names = {'TimeScaling'};
    defaults = {robotics.core.internal.constructLinearTimeScaling(timeInterval, t)};
    parser = robotics.core.internal.NameValueParser(names, defaults);
    parse(parser, charInputs{:});
    timeScaling = parameterValue(parser, names{1});

    % Input checks
    timeScaling = robotics.core.internal.validateTimeScaling(timeScaling, m, 'transformtraj');

    % Compute rotation transform
    r1 = tform0(1:3,1:3);
    r2 = tformF(1:3,1:3);

    % Process time scaling
    s = timeScaling(1,:);
    sd = timeScaling(2,:);
    sdd = timeScaling(3,:);

    % Compute rotation trajectory
    [r,w,a] = rottraj(r1,r2,timeInterval,t,'TimeScaling', timeScaling);

    % Initialize outputs
    tformCalc = zeros(4,4,m,'like',tform0);
    tformCalc(4,4,:) = 1;
    vel = zeros(6,m,'like',tform0);
    acc = zeros(6,m,'like',tform0);

    % Compute translation transform
    p0 = tform0(1:3,4);
    pF = tformF(1:3,4);
    p = repmat(p0, 1, m) + (pF - p0)*s;
    pd = (pF - p0)*sd;
    pdd = (pF - p0)*sdd;

    % Concatenate outputs
    tformCalc(1:3,1:3,:) = r;
    tformCalc(1:3,4,:) = p;
    vel(1:3,:) = w;
    vel(4:6,:) = pd;
    acc(1:3,:) = a;
    acc(4:6,:) = pdd;

    switch inputType
      case 'se3'
        % Return as se3 object array
        tform = se3(tformCalc).';
      case 'tform'
        % Transformation matrix (numeric)
        tform = tformCalc;
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
        % se3 object
        inputType = 'se3';
      case 4
        % Rotation matrix
        inputType = 'tform';
    end
end
function tf = validateTransformationInput(tformInput, inputName)
%validateTransformationInput Verify transformation and convert to numeric matrix
    if isa(tformInput, 'se3') && isscalar(tformInput)
        %Scalar se3 object. Extract raw transformation matrix
        tf = tform(tformInput);
    elseif all(size(tformInput) == [4 4])
        %Verify that this is a valid transformation matrix
        robotics.internal.validation.validateHomogeneousTransform(tformInput, 'transformtraj', inputName);
        tf = tformInput;
    else
        coder.internal.errorIf(true, 'shared_robotics:robotcore:utils:TransformTrajInvalidInput', inputName);
    end
end
