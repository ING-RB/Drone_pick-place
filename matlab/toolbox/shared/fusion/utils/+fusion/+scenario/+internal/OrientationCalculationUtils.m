classdef OrientationCalculationUtils < handle
% This file is for internal use only.
% It may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.

%OrientationCalculationUtils Provide methods for calculating
%orientation

%#codegen

    methods(Static)

        function [orientation, angularVelocity] = getOrientationAndAngularVelocity(uVector, vVector, wVector, ...
                                                                                   duVector, dvVector, dwVector)
        %getOrientationAndAngularVelocity Calculate orientation and
        %angular velocity from unit vectors.

        % determine angular velocity
            n = size(uVector,1);
            RR = zeros(3,3,n);
            angularVelocity = zeros(n,3);
            for i=1:n
                R = [uVector(i,:); vVector(i,:); wVector(i,:)]';
                dR = [duVector(i,:); dvVector(i,:); dwVector(i,:)]';
                W = dR * R';
                angularVelocity(i,:) = [W(3,2) W(1,3) W(2,1)];
                angularVelocity(i,~isfinite(angularVelocity(i,:))) = 0;
                if any(~isfinite(R(:)))
                    R = eye(3);
                end
                RR(:,:,i) = R.';
            end
            orientation = quaternion(RR, 'rotmat', 'frame');
        end

        function [vVector, dvVector, wVector, dwVector] = fixedWing(acceleration, jerk, uVector, duVector, gravity)
        %fixedWing Calculate unit vectors when
        %AutoRoll=true and AutoPitch=true
        %uVector and duVector are the unit vector and its derivative
        %calculated from the velocity. wVector and its derivative are
        %calculated in the direction of the net acceleration and vVector is
        %calculated to satisfy the right-handed coordinate system.
        % compute vector rejection of net acceleration to x vector
            netAccel = bsxfun(@minus, gravity, acceleration);

            bankVector = netAccel - bsxfun(@times, dot(netAccel,uVector,2), uVector);
            dbankVector = -jerk   - bsxfun(@times, dot(netAccel,uVector,2), duVector) ...
                - bsxfun(@times, dot(netAccel,duVector,2) + dot(-jerk,uVector,2), uVector);

            [wVector, dwVector] = fusion.scenario.internal.OrientationCalculationUtils.unitd(bankVector, dbankVector);

            % when in an ENU convention we need to invert the sense of the
            % vector to prevent inversion about the x-y plane
            % in both conventions, u corresponds to "forward"
            % in an NED axis convention, v and w correspond to "right" and "down"
            % in an ENU axis convention, v and w correspond to "left" and "up"
            %
            % If gravity has a negative component, we assume we are in ENU
            % and need to flip the sign so we properly align the w axis.
            wVector = bsxfun(@times, sign(gravity(:,3)), wVector);
            dwVector = bsxfun(@times, sign(gravity(:,3)), dwVector);

            % obey right-handed coordinate system.
            [vVector,dvVector] = fusion.scenario.internal.OrientationCalculationUtils.crossd(wVector, uVector, dwVector, duVector);
        end

        function [vVector, dvVector, wVector, dwVector] = groundVehicle(uVector, duVector)
        %groundVehicle Calculate unit vectors when
        %AutoPitch=true and AutoRoll=false
        %uVector and duVector are the unit vector and its derivative
        %calculated from the velocity. wVector aligns with the vertical orientation.
        % vVector is the unit vector which results from uXw. wVector is
        % then recalculated to satisfy the right handed system
        % align w with vertical orientation.
            n = size(uVector,1);
            wVector = repmat([0 0 1],n,1);
            dwVector = zeros(n,3);

            [WxU,dWxU] = fusion.scenario.internal.OrientationCalculationUtils.crossd(wVector, uVector, dwVector, duVector);
            [vVector,dvVector] = fusion.scenario.internal.OrientationCalculationUtils.unitd(WxU,dWxU);

            % align w to obey right-handed coordinate system U x V = W.
            [wVector, dwVector] = fusion.scenario.internal.OrientationCalculationUtils.crossd(uVector,vVector,duVector,dvVector);
        end

        function [uVector, duVector, vVector, dvVector, wVector, dwVector] = rotaryWing(acceleration, jerk, uTangent, duTangent, alignment, gravity)
        %rotaryWing Calculate unit vectors when
        %AutoPitch=false and AutoRoll=true
        %uVector is the unit vector of the horizontal velocity(As pitch is
        %0). wVector aligns with the acceleration. vVector is the result of
        %wXu and then the uVector is recomputed to satisfy right handed
        %conditions.

        % compute net (lateral and vertical) acceleration
            netAccel = bsxfun(@minus, gravity, acceleration);

            [wVector, dwVector] = fusion.scenario.internal.OrientationCalculationUtils.unitd(netAccel, -jerk);

            % when in an ENU convention we need to invert the sense of the
            % vector to prevent inversion about the x-y plane
            % in both conventions, u corresponds to "forward"
            % in an NED axis convention, v and w correspond to "right" and "down"
            % in an ENU axis convention, v and w correspond to "left" and "up"
            %
            % If gravity has a negative component, we assume we are in ENU
            % and need to flip the sign so we properly align the w axis.
            wVector = bsxfun(@times, sign(gravity(:,3)), wVector);
            dwVector = bsxfun(@times, sign(gravity(:,3)), dwVector);

            % align unit left vector to be normal to horizontal velocity and up direction
            uVector = alignment .* uTangent(:,1:3);
            duVector = alignment .* duTangent(:,1:3);

            [WxU,dWxU] = fusion.scenario.internal.OrientationCalculationUtils.crossd(wVector, uVector, dwVector, duVector);
            [vVector,dvVector] = fusion.scenario.internal.OrientationCalculationUtils.unitd(WxU,dWxU);

            % re-compute forward vector
            [uVector, duVector] = fusion.scenario.internal.OrientationCalculationUtils.crossd(vVector,wVector,dvVector,dwVector);
        end

        function [uVector, duVector, vVector, dvVector, wVector, dwVector] = marineVehicle(uTangent, duTangent, alignment)
        %marineVehicle Calculate unit vectors when AutoPitch
        %and AutoRoll are false
        %wVector aligns with the vertical, uVector is the direction of the
        %horizontal velocity and vVector is the result of wXu.
        % align w with vertical orientation.
            n = size(uTangent,1);
            wVector = repmat([0 0 1],n,1);
            dwVector = zeros(n,3);

            % align unit forward vector with velocity's projection into x-y plane
            % (provide MATLAB Coder with size hint)
            uVector = alignment .* uTangent(:,1:3);
            duVector = alignment .* duTangent(:,1:3);

            % align left vector in x-y plane
            [vVector,dvVector] = fusion.scenario.internal.OrientationCalculationUtils.crossd(wVector, uVector, dwVector, duVector);
        end

        function [u, du] = unitd(v, dv)
        % compute unit vector and its derivative
            vmag = vecnorm(v,2,2);
            u = bsxfun(@rdivide, v, vmag);
            du = bsxfun(@rdivide, dv, vmag) - bsxfun(@times, v, dot(v, dv, 2) ./ vmag.^3);
        end

        function [AxB, dAxB] = crossd(A,B,dA,dB)
        % compute cross product and its derivative
            AxB = cross(A,B,2);
            dAxB = cross(A,dB,2) + cross(dA,B,2);
        end
    end
end
