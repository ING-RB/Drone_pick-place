function [ q, qd, qdd, pp] = quinticpolytraj( wayPoints, timePoints, t, varargin)
%QUINTICPOLYTRAJ Generate fifth-order trajectories through multiple waypoints
%   [Q, QD, QDD, PP] = quinticpolytraj(WAYPOINTS, TIMEPOINTS, T) generates
%   a fifth-order polynomial trajectory that achieves a given set of input
%   waypoints with their corresponding time points. The function outputs
%   positions, Q, velocities, QD, and accelerations, QDD, at the given time
%   samples, T. It also outputs the ppforms of the polynomial for the
%   trajectory in PP.
%
%      WAYPOINTS  - An N x P matrix specifying P waypoints that are each an
%                   N x 1 vector of positions.
%
%      TIMEPOINTS - A 1xP vector of times corresponding to the timing of
%                   each associated waypoint.
%
%      T          - A sampled 1xM time vector from zero to the final time.
%
%   [Q, QD, QDD, PP] = quinticpolytraj(___, Name, Value)
%   provide additional options for polynomial interpolation specified by
%   Name-Value pair arguments.
%
%      'VelocityBoundaryCondition'    -  The velocity boundary conditions,
%                                        specified as an N x P matrix of
%                                        velocities at each waypoint. By
%                                        default, this is assumed to be
%                                        zero.
%
%      AccelerationBoundaryCondition'  - The acceleration boundary
%                                        conditions, specified as an N x P
%                                        matrix of accelerations at each
%                                        waypoint. By default, this is
%                                        assumed to be zero.
%
%   Example:
%      % Define time and position waypoints
%      tpts = 0:5;
%      wpts = [1 4 4 3 -2 0; 0 1 2 4 3 1];
%
%      % Define time vector
%      tvec = 0:0.01:5;
%
%      % Compute trajectory using default boundary conditions
%      [q, qd, qdd, pp] = quinticpolytraj(wpts, tpts, tvec);
%
%      % Plot results. The x's are waypoints, and the lines are the derived
%      % polynomial curves
%      plot(tvec, q)
%      hold all
%      plot(tpts, wpts, 'x')
%      hold off
%
%   See also BSPLINEPOLYTRAJ, CUBICPOLYTRAJ, TRAPVELTRAJ

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    narginchk(3,7)

    % Convert strings to chars case by case for codegen support
    if nargin > 5
        charInputs = cell(1,4);
        [charInputs{:}] = convertStringsToChars(varargin{:});
    elseif nargin > 3
        charInputs = cell(1,2);
        [charInputs{:}] = convertStringsToChars(varargin{:});
    else
        charInputs = {};
    end

    % Check input validity
    validateattributes(wayPoints, {'numeric'}, {'2d','nonempty','real','finite'}, 'quinticpolytraj','wayPoints');
    validateattributes(timePoints, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'quinticpolytraj','timePoints');

    % Ensure timePoints is a row
    timePoints = timePoints(:)';

    % Establish some dimensions
    n = size(wayPoints,1);
    p = size(wayPoints,2);

    % Parse inputs
    names = {'VelocityBoundaryCondition','AccelerationBoundaryCondition'};
    defaults = {zeros(n,p),zeros(n,p)};
    parser = robotics.core.internal.NameValueParser(names, defaults);
    parse(parser, charInputs{:});
    velBC = parameterValue(parser, names{1});
    accBC = parameterValue(parser, names{2});

    % Input checks
    coder.internal.errorIf(length(timePoints) ~= p, 'shared_robotics:robotcore:utils:WayPointMismatch');
    coder.internal.errorIf(size(velBC,1) ~= n || size(velBC,2) ~= p, 'shared_robotics:robotcore:utils:WaypointVelocityBCDimensionMismatch');
    coder.internal.errorIf(size(accBC,1) ~= n || size(accBC,2) ~= p, 'shared_robotics:robotcore:utils:WaypointAccelerationBCDimensionMismatch');

    % Initialize output arrays
    q = zeros(n, length(t));
    qd = zeros(n, length(t));
    qdd = zeros(n, length(t));

    % Initialize the coefficient matrix to zeros. For P waypoints, there are
    % (P-1 segments) x (N dimensions) of polynomials, each with six
    % coefficients.
    coeffdim = 6;
    coefMat = zeros((p-1)*n,coeffdim);

    % Polynomial implementation: solve for the coefficients by segment on an
    % interval from zero to the segment end time.
    for i = 1:p-1
        % Get the final time, which indicates segment length
        finalTime = timePoints(i+1) - timePoints(i);

        % Solve for the coefficients along each dimension
        coeffMat = zeros(n,coeffdim);
        for j = 1:n
            coeffMat(j,:) = generateQuinticCoeffs(wayPoints(j,i:i+1), velBC(j, i:i+1), accBC(j, i:i+1), finalTime);

            % Store for pp-form output
            cidx = (i-1)*n + j;
            coefMat(cidx, :) = coeffMat(j,:);
        end
    end

    % Add flat segments to the start and end of each trajectory so the
    % values will be held constant outside the user-specified time values
    [modBreaks, modCoeffs] = robotics.core.internal.addFlatSegmentsToPPFormParts(timePoints, coefMat, n);

    % Compute pp-forms and evaluate using ppval
    pp = mkpp(modBreaks, modCoeffs, n);
    q(:,:) = ppval(pp, t);

    % Only compute velocity and acceleration if needed
    if nargout > 1
        % In order for derivatives to have nonzero values at final time, the
        % second to last break must extend past the final time in the
        % derivative coefficients
        derivativeBreaks = robotics.core.internal.changeEndSegBreaks(modBreaks, t);

        % Get coefficients for first derivative pp-form and evaluate
        dCoeffs = robotics.core.internal.polyCoeffsDerivative(modCoeffs);
        ppd = mkpp(derivativeBreaks, dCoeffs, n);
        qd(:,:) = ppval(ppd, t);
    end

    if nargout > 2
        % Get coefficients for second derivative pp-form and evaluate
        ddCoeffs = robotics.core.internal.polyCoeffsDerivative(dCoeffs);
        ppdd = mkpp(derivativeBreaks, ddCoeffs, n);
        qdd(:,:) = ppval(ppdd, t);
    end

end

%% Helper Functions

function coeffVec = generateQuinticCoeffs(posPts, velPts, accPts, finalTime)
%generateQuinticCoeffs Compute coefficients of a quintic polynomial segments
%   This function computes the quintic polynomial coefficients given the
%   bounding positions, velocities, and accelerations of a segment defined
%   from t=0 to t=finalTime.

% Define initial and final position, velocity, and acceleration
    x0 = posPts(1);
    dx0 = velPts(1);
    ddx0 = accPts(1);

    xT = posPts(2);
    dxT = velPts(2);
    ddxT = accPts(2);

    % First three coefficients can be found by setting t=0 using boundary
    % conditions
    coeffVec = [x0 dx0 ddx0/2 0 0 0]';

    % The last three coefficients may be found by substituting the first three
    % into the expressions for position, velocity, and acceleration at
    % t=finalTime:
    % [q(T) qd(T) qdd(T)]' = TMat0*[C1 C2 C3]' + TMatF*[C4 C5 C6]
    % where TMatF =
    %   [finalTime^3    finalTime^4     finalTime^5; ...
    %    3*finalTime^2  4*finalTime^3   5*finalTime^4; ...
    %    6*finalTime    12*finalTime^2  20*finalTime^3];
    % This expression may be solve for C4, C5, and C6
    TMat0 = [1 finalTime finalTime^2; 0 1 2*finalTime; 0 0 2];
    B = [xT; dxT; ddxT] - TMat0*coeffVec(1:3);

    % Since Tmat is a known function of finalTime, use the analytical inverse
    % of TMatF to avoid numerical issues:
    invTMatF = [10/finalTime^3 -4/finalTime^2 1/(2*finalTime); ...
                -15/finalTime^4 7/finalTime^3 -1/finalTime^2; ...
                6/finalTime^5 -3/finalTime^4, 1/(2*finalTime^3)];
    coeffVec(4:6) = invTMatF * B;

    % Flip the order to match standard form
    coeffVec = fliplr(coeffVec');

end
