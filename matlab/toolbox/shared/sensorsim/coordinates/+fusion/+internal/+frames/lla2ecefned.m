function [Xecef, Vned, Aned, Jned] = lla2ecefned(lla, llavel, llaacc, llajer)
%ECEFNED2GEODETIC converts geodetic coordinates and their derivatives into
%   Cartesian coordinates in ECEF axes (position only) and in NE axes
%   (velocity, acceleration, and jerk)
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    Xecef = fusion.internal.frames.lla2ecef(lla);
    coslat = cosd(lla(:,1));
    sinlat = sind(lla(:,1));
    R = vecnorm(Xecef,2,2);
    lamdot = deg2rad(llavel(:,1));
    lamacc = deg2rad(llaacc(:,1));
    lamjer = deg2rad(llajer(:,1));
    mudot = deg2rad(llavel(:,2));
    muacc = deg2rad(llaacc(:,2));
    mujer = deg2rad(llajer(:,2));
    Rdot = llavel(:,3);
    

    % Velocity
    Vdown = - Rdot;
    Veast = mudot.*R.*coslat;
    Vnorth = lamdot.*R;
    Vned = [Vnorth, Veast, Vdown];

    % Acceleration
    Anorth = R.*lamacc+2*Rdot.*lamdot + R.*sinlat.*coslat.*mudot.^2;
    Aeast = R.*coslat.*muacc + 2*mudot.*(Rdot.*coslat - R.*lamdot.*sinlat);
    Adown = - llaacc(:,3) + R.*lamdot.^2 + R.*(coslat.*mudot).^2;
    Aned = [Anorth, Aeast, Adown];

    % Jerk
    Anorthdot = 3*Rdot.*lamacc + 2*llaacc(:,3).*lamdot + R.*lamjer + ...
        Rdot.*sinlat.*coslat.*mudot.^2 + 2.*R.*muacc.*mudot.*sinlat.*coslat + ...
        R.*mudot.^2.*lamdot.*cosd(2*lla(:,1));

    Aeastdot = 3*muacc.*(Rdot.*coslat-R.*sinlat.*lamdot) + R.*coslat.*mujer + ...
        2*mudot.*(llaacc(:,3).*coslat - ...
                  2*Rdot.*lamdot.*sinlat - ...
                  R.*lamacc.*sinlat - ...
                  R.*lamdot.^2.*coslat);

    Adowndot = - llajer(:,3) + Rdot.*lamdot.^2 + 2*R.*lamacc.*lamdot + Rdot.*coslat.^2.*mudot.^2 - ...
        2*R.*lamdot.*sinlat.*coslat.*mudot.^2 + 2.*R.*muacc.*mudot.*coslat.^2;

    omega = [mudot.*coslat , -lamdot, -mudot.*sinlat];

    Jned = [Anorthdot, Aeastdot, Adowndot] + cross(omega, Aned, 2);


end
