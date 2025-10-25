function [orientation, angularVelocity] = getOrientationFromPath( ...
    velocity, acceleration, jerk, autoPitch, autoRoll, gravity, ...
    alignment, hut, dhut, vs, hs, va, ha, vj, hj)
%

% This file is for internal use only.
% It may be removed in a future release.

%   Copyright 2017-2023 The MathWorks, Inc.

%  velocity      - N-by-3 velocity in x-, y-, z- directions
%  acceleration  - N-by-3 velocity in x-, y-, z- directions
%  jerk          - N-by-3 velocity in x-, y-, z- directions
%
%  autoBank   - pitch and roll compensate for gravity when true
%  autoPitch  - lock pitch to direction of motion when true, regardless
%               of autobank setting
%  gravity    - local gravity at each point -ve for ENU, +ve for NED
%  alignment  - +1 to align yaw with course, -1 to align oppositely
%
%  hut, dhut - horizontal unit tangent in complex plane and its derivative.
%  vs, hs    - vertical signed-speed and horizontal speed in complex plane.
%  va, ha    - vertical and horizontal sign-magnitude acceleration
%  vj, hj    - vertical and horizontal sign-magnitude jerk


%#codegen
% To construct the rotation matrix, we compute row vectors:
%  R = [u' v' w'].
%
%  u, v, and w obey a right-handed coordinate system (u x v = w):
%    (w = u x v, u = v x w, v = w x u).
%
%  For ENU: u, v, and w correspond to "forward" "left" and "up"
%  For NED: u, v, and w correspond to "forward" "right" and "down"
%
%  when R = eye(3), then object is aligned with its coordinate system.

%Calculate the unit vectors based on the provided options
    if autoPitch
        if nargin < 7
            % align unit tangent vector with 3-D velocity
            [uTangent, duTangent] = fusion.scenario.internal.OrientationCalculationUtils.unitd(velocity, acceleration);
            alignment = ones(size(velocity,1),1);
        else
            % align unit tangent vector with horizontal complex unit tangent
            % rotated into 3-D space by vertical and horizontal time derivatives
            [uTangent,duTangent] = evaltangent(hut,dhut,vs,hs,va,ha,vj,hj);
        end

        uVector = alignment .* uTangent;
        duVector = alignment .* duTangent;

        if autoRoll
            [vVector, dvVector, wVector, dwVector] = ...
                fusion.scenario.internal.OrientationCalculationUtils.fixedWing(acceleration, jerk, uVector, duVector, gravity);
        else
            [vVector, dvVector, wVector, dwVector] = ...
                fusion.scenario.internal.OrientationCalculationUtils.groundVehicle(uVector, duVector);
        end
    else
        % set tangent vector to horizontal plane.
        if nargin < 7
            hVel = [velocity(:,1:2) zeros(size(velocity,1),1)];
            hAcc = [acceleration(:,1:2) zeros(size(velocity,1),1)];
            [uTangent, duTangent] = fusion.scenario.internal.OrientationCalculationUtils.unitd(hVel, hAcc);
            alignment = ones(size(velocity,1),1);
        else
            uTangent = [real(hut) imag(hut) zeros(numel(hut),1)];
            duTangent = [real(dhut) imag(dhut) zeros(numel(hut),1)];
        end

        if autoRoll
            [uVector, duVector, vVector, dvVector, wVector, dwVector] = ...
                fusion.scenario.internal.OrientationCalculationUtils.rotaryWing(acceleration, jerk, uTangent, duTangent, alignment, gravity);
        else
            [uVector, duVector, vVector, dvVector, wVector, dwVector] = ...
                fusion.scenario.internal.OrientationCalculationUtils.marineVehicle(uTangent, duTangent, alignment);
        end
    end

    %Calculate the orientation and angular velocity from the unit vectors
    [orientation, angularVelocity] = fusion.scenario.internal.OrientationCalculationUtils.getOrientationAndAngularVelocity(uVector, vVector, wVector, ...
                                                                                                                           duVector, dvVector, dwVector);
end


function [utangent,dutangent] = evaltangent(hut,dhut,vs,hs,va,ha,vj,hj)
%   return the unit tangent vector, UTANGENT, and its derivative DUTANGENT,
%   by rotating the unit tangent in the (horizontal) complex plane, HUT,
%   and its derivative, DHUT, into cartesian 3-space by examining the
%   horizontal and vertical speeds (VS, HS) and their first (VA, HA) and
%   second derivatives (VJ, HJ), respectively.

% total speed
    ts = hypot(vs,hs);

    % compute ratio of vertical to total speed and its derivative.
    s = vs./ts;
    ds = va./ts - vs.*(vs.*va+hs.*ha)./ts.^3;

    % compute ratio of horizontal to total speed and its derivative.
    c = hs./ts;
    dc = ha./ts - hs.*(vs.*va+hs.*ha)./ts.^3;

    % use L'Hospital rule for indeterminate forms
    idx = find(ts<sqrt(eps(1)));
    ta = hypot(va(idx),ha(idx));

    s(idx) = va(idx)./hypot(va(idx),ha(idx));
    ds(idx) = vj(idx)./ta - va(idx).*(va(idx).*vj(idx)+ha(idx).*hj(idx))./ta.^3;

    c(idx) = ha(idx)./hypot(va(idx),ha(idx));
    dc(idx) = hj(idx)./ta - ha(idx).*(va(idx).*vj(idx)+ha(idx).*hj(idx))./ta.^3;

    % if velocity is negative with positive acceleration or vice-versa,
    % invert the sign as we have not yet arrived at the zero.
    nidx = idx(hs(idx)<0 & ha(idx)>0 | hs(idx)>0 & ha(idx)<0);
    s(nidx) = -s(nidx);
    c(nidx) = -c(nidx);
    ds(nidx) = -ds(nidx);
    dc(nidx) = -dc(nidx);

    % align with horizontal plane when no more derivatives exist
    c(isnan(s)) = 1;
    s(isnan(s)) = 0;

    % do not report angular pitch velocity when total speed is zero
    ds(isnan(ds)) = 0;
    dc(isnan(dc)) = 0;

    % compute unit tangent of 3-d path
    utangent = [c.*real(hut) c.*imag(hut) s];
    dutangent = [c.*real(dhut)+dc.*real(hut) c.*imag(dhut)+dc.*imag(hut) ds];
end
