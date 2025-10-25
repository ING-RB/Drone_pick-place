function [frenetState, lTime] = cartesian2Frenet(refState, queryState)
%cartesian2Frenet convert from Cartesian to Frenet
%   frenetState converts states [x, y, theta, kappa, v, a] to
%   [s, sDot, sDotDot, l, lPrime, lPrimePrime] using the
%   reference point which contains [x,y,theta,kappa,dkappa,s]

%   Copyright 2021 The MathWorks, Inc.

    %#codegen
    
    % Validate number of input arguments
    narginchk(2,2)

    % Segregate reference states
    refS = refState(:,6);
    refX = refState(:,1);
    refY = refState(:,2);
    refTheta = robotics.internal.wrapToPi(refState(:,3));
    refKappa = refState(:,4);
    refKappaPrime = refState(:,5);

    % Segregate query Cartesian states
    x = queryState(:,1);
    y = queryState(:,2);
    v = queryState(:,5);
    a = queryState(:,6);
    theta = robotics.internal.wrapToPi(queryState(:,3));
    kappa = queryState(:,4);

    dx = x - refX;
    dy = y - refY;

    refCosTheta = cos(refTheta);
    refSinTheta = sin(refTheta);

    % Normal at the root point
    refNormal = refCosTheta .* dy - refSinTheta .* dx;

    % Compute lateral deviation
    l = vecnorm([dx, dy]')' .* sign(refNormal);

    deltaTheta = robotics.internal.angdiff(refTheta,theta);

    tanDeltaTheta = tan(deltaTheta);
    cosDeltaTheta = cos(deltaTheta);

    oneMinusKappaRefL = 1 - refKappa .* l;

    % Throw an error if point lies beyond radius of curvature.
    errorCondition = oneMinusKappaRefL <= 0;
    if nargout == 1
        % If lateral time derivatives have not been provided, throw
        % error when heading deviation exceeds pi/2
        errorCondition = errorCondition | abs(deltaTheta) >= pi/2;
    end

    % Throw error if all states are invalid
    coder.internal.errorIf(all(errorCondition), ...
        'shared_autonomous:cartesianFrenetConversions:singularity');

    % Compute derivative of lateral deviation w.r.t. arc length
    lPrime = oneMinusKappaRefL .* tanDeltaTheta;

    kappaRefLPrime = refKappaPrime .* l + refKappa .* lPrime;
    
    % Compute second derivative of lateral deviation w.r.t. arc length
    lPrimePrime = -kappaRefLPrime .* tanDeltaTheta + oneMinusKappaRefL ./ cosDeltaTheta ./ cosDeltaTheta .* (kappa .* oneMinusKappaRefL ./ cosDeltaTheta - refKappa);

    % Arc length is same as reference (root point) arc length
    s = refS;

    % Velocity in lateral direction
    sDot = v .* cosDeltaTheta ./ oneMinusKappaRefL;

    deltaThetaPrime = oneMinusKappaRefL ./ cosDeltaTheta .* kappa - refKappa;

    % Acceleration in lateral direction
    sDotDot = (a .* cosDeltaTheta - sDot.^2 .* (lPrime .* deltaThetaPrime - kappaRefLPrime)) ./ oneMinusKappaRefL;

    % Consolidate all the states as a 1x6 vector
    frenetState = [s sDot sDotDot l lPrime lPrimePrime];

    % Calculate time-based derivatives if requested
    if nargin == 2
        lDot = v.*sin(deltaTheta);
        lDotDot = (v.*a - sDot.*sDotDot.*(1-refKappa.*l).^2 + sDot.^2.*(1-refKappa.*l).*(lDot.*refKappa+l.*sDot.*refKappaPrime))./lDot;
        
        % Protect against degenerate cases where ddL->0
        m = abs(lDot) <= sqrt(eps);
        lDotDot(m) = lPrimePrime(m).*sDot(m).^2 + lPrime(m).*sDotDot(m);
        mLeftHalf = (v == 0 & cos(deltaTheta) < 0);
        lTime = [lDot, lDotDot, v < 0 | mLeftHalf];
        frenetState(mLeftHalf,5) = -frenetState(mLeftHalf,5);
    end
end
