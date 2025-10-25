function cartesianState = frenet2Cartesian(refPoint, queryState)
%frenet2Cartesian Convert from Frenet to Cartesian
%   Converts Frenet queryState [s, sDot, sDotDot, l, lPrime, lPrimePrime]
%   to global cartesianState [x, y, theta, kappa, v, a] using the reference
%   point refPoint [x, y, theta, kappa, dkappa, s].

%   Copyright 2021 The MathWorks, Inc.

    %#codegen

    % Validate number of input arguments
    narginchk(2,2)

    % Segregate reference points
    [xR,yR,thR,kR,dkR,~] = breakPathPoint(refPoint);
    
    % Segregate queried Frenet states
    [~,dS,ddS,L,Lp,Lpp] = breakFrenetState(queryState);

    % Compute x
    x = xR - sin(thR) .* L;

    % Compute y
    y = yR + cos(thR) .* L;

    % Calculate the factor which scales the path-concentric velocity along
    % the trajectory to a longitudinal velocity on the path:
    dsScaleFactor = 1 - kR .* L;

    tanDeltaTheta = Lp ./ dsScaleFactor;
    deltaTheta    = atan2(Lp, dsScaleFactor);
    cosDeltaTheta = cos(deltaTheta);

    % Throw an error at extreme curvature or deltaTheta >= pi/2
    coder.internal.errorIf(all(dsScaleFactor <= 0 | abs(deltaTheta) >= pi/2), ...
                           'shared_autonomous:cartesianFrenetConversions:singularity');

    % Compute theta
    theta = robotics.internal.wrapToPi(deltaTheta + thR + 2*pi);

    kappaRefLPrime = dkR .* L + kR .* Lp;

    % Compute kappa
    kappa = (((Lpp + kappaRefLPrime .* tanDeltaTheta) .* cosDeltaTheta.^2) ./ dsScaleFactor + kR) .* cosDeltaTheta ./ dsScaleFactor;

    % Compute speed in the direction of vehicle heading
    v = dS .* (dsScaleFactor ./ cosDeltaTheta);

    deltaThetaPrime = dsScaleFactor ./ cosDeltaTheta .* kappa - kR;

    % Compute acceleration in the direction of vehicle heading
    a = (ddS .* dsScaleFactor ./ cosDeltaTheta) + (dS.^2 ./ cosDeltaTheta) .* (Lp .* deltaThetaPrime - kappaRefLPrime);

    % Consolidate all the states as a 1x6 vector
    cartesianState = [x y theta kappa v a];
end

function [x,y,theta,k,dk,s] = breakPathPoint(stateMatrix)
%breakPathPoint Break curve point matrix into vectors
    x = stateMatrix(:,1);
    y = stateMatrix(:,2);
    theta = robotics.internal.wrapToPi(stateMatrix(:,3));
    k = stateMatrix(:,4);
    dk = stateMatrix(:,5);
    s = stateMatrix(:,6);
end

function [S,dS,ddS,L,Lp,Lpp] = breakFrenetState(stateMatrix)
%breakGlobalState Break Frenet state matrix into vectors
    S = stateMatrix(:,1);
    dS = stateMatrix(:,2);
    ddS = stateMatrix(:,3);
    L = stateMatrix(:,4);
    Lp = stateMatrix(:,5);
    Lpp = stateMatrix(:,6);
end
