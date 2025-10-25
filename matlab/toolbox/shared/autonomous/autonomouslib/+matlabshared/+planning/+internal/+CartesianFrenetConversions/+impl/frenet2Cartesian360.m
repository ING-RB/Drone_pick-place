function cartesianStates = frenet2Cartesian360(refPoint, queryState, timeDerivative)
%frenet2Cartesian360 Convert Frenet states to Cartesian with support for reverse motion and heading
%
%   Converts Frenet queryState, [S dS/dt ddS/dt^2 L dL/dS ddL/dS^2] 
%   and accompanying timeDerivative info [dL/dt ddL/dt^2 invertHeadingTF]
%   to global coordinates [x, y, theta, kappa, v, a] using a reference 
%   point along the path which contains [x, y, theta, kappa, dkappa, s]
%
%   The time derivatives and heading information included in this syntax 
%   allow us to distinguish between a) states whose motion is counteraligned
%   with their heading and b) states with angular deviation, deltaTheta,
%   between their heading and the path tangent angle is greater-than > pi/2. 
%   Similarly, the inclusion of time-derivatives allows us to handle 
%   singularities, e.g. states oriented perpendicular to the path 
%   (|deltaTheta| == pi/2), and states with zero velocity.

%   Copyright 2021 The MathWorks, Inc.

    %#codegen

    % Validate number of input arguments
    narginchk(3,3);
    n = size(queryState,1);
    cartesianStates = zeros(n,6);
    for ii = 1:n
        cartesianStates(ii,:) = frenet2GlobalWithTimeDerivative(refPoint(ii,:),queryState(ii,:),timeDerivative(ii,:));
    end
end

function globalState = frenet2GlobalWithTimeDerivative(refPoint, queryState, latTimeDeriv)
%frenet2GlobalWithTimeDerivative Convert a single Frenet state to global coordinates and handle edge cases
    
    % Segregate reference points
    [xR,yR,thR,kR,dkR,~] = breakPathPoint(refPoint);
    
    % Segregate queried Frenet states
    [~,dS,ddS,L,Lp,Lpp] = breakFrenetState(queryState);

    % Segregate time-derivatives
    [dL,ddL,invertHeading] = breakDerivs(latTimeDeriv);
    
    % Check whether velocity is degenerate
    mZeroVel = dL == 0 && dS == 0;

    % Calculate the factor which scales the path-concentric velocity along
    % the trajectory to a longitudinal velocity on the path:
    dsScaleFactor = 1 - kR*L;

    %% Calculate orientation
    if mZeroVel
    % Orientation, curvature, and velocity must be calculated using s-derivatives

        v = 0;

        % Calculate deltaTheta, the angle between state orientation and path-tangent.
        if invertHeading == 1
        % If the invertHeading flag is true when v==0, it means Lprime 
        % has been flipped to account for orientation across y-axis (since
        % the sign of dS is lost when v->0.
            
            % Calculate the angle in the opposite hemisphere
            deltaTheta = atan2(Lp, -dsScaleFactor);

            % Flip the sign of Lprime back to the original value for 
            % subsequent calculations of kappa, velocity, and acceleration.
            Lp = -Lp;
        else
            deltaTheta = atan2(Lp, dsScaleFactor);
        end
        
        tanDT = tan(deltaTheta);
        cosDT = cos(deltaTheta);
        sinDT = sin(deltaTheta);

        % Check whether orientation is degenerate
        mPerpOrient = abs(cosDT) < 1e-10;
    else
    % Calculate orientation using time-derivatives
    
        if invertHeading
            deltaTheta = robotics.internal.wrapToPi(atan2(dL,dS-dS*kR*L)+pi);
        else
            deltaTheta = robotics.internal.wrapToPi(atan2(dL,dS-dS*kR*L));
        end

        tanDT = dL/(dS-dS*kR*L);
        cosDT = cos(deltaTheta);
        sinDT = sin(deltaTheta);

        % Calculate L-prime using time-based derivatives
        Lp = dL/dS;

        % Calculate L-double-prime using time-based derivatives
        Lpp = (ddL-Lp*ddS)/dS^2;

        % Check whether orientation is degenerate
        mPerpOrient = abs(cosDT) < 1e-10;
    
        % Calculate body velocity
        if mPerpOrient
            % When orientation is very close to perpendicular, velocity
            % effectively becomes dL/dt.
            v = dL/sinDT;
        else
            % When far from perpendicular, use the reference paper's cosine
            % evaluation.
            v = dS*dsScaleFactor/cosDT;
        end
    end

    % Calculate curvature
    kR_Lp = dkR * L + kR * Lp;
    A = Lpp + kR_Lp*tanDT;
    kappa = (A*cosDT^2/dsScaleFactor + kR)*cosDT/dsScaleFactor;

    if mPerpOrient && ~mZeroVel
        % Even when perpendicular, we can still recover curvature so long 
        % as v=/=0, since it reduces to centripetal acceleration.
        kSign = sign(-sinDT*ddS);
        kappa = abs(ddS)/dL^2*kSign;
    end

    % Calculate acceleration
    if mPerpOrient
        % In the degenerate case, body-acceleration simplifies to
        % acceleration along the normal to the curve, and the sign is
        % determined by sin(deltaTheta).
        a = ddL*sinDT;
    else
        deltaThetaPrime = kappa * dsScaleFactor / cosDT - kR;
        aTangential = ddS * dsScaleFactor / cosDT;
        aCentripetal = (dS^2 / cosDT) * (Lp * deltaThetaPrime - kR_Lp);
        a = aTangential + aCentripetal;
    end

    % Compute x,y
    x = xR - sin(thR) * L;
    y = yR + cos(thR) * L;
    
    % Wrap theta
    theta = robotics.internal.wrapToPi(thR + deltaTheta);

    % Return state
    globalState = [x y theta kappa v a];
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

function [dL, ddL, invertHeading] = breakDerivs(derivMatrix)
%breakDerivs Break lateral derivative matrix into vectors
    dL = derivMatrix(:,1);
    ddL = derivMatrix(:,2);
    invertHeading = derivMatrix(:,3);
end
