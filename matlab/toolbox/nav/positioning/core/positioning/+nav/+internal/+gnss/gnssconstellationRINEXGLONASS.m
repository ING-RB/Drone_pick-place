classdef (Hidden) gnssconstellationRINEXGLONASS < nav.internal.gnss.gnssconstellationRINEX
%GNSSCONSTELLATIONRINEXGLONASS Satellite motion parameters from RINEX GLONASS data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        function varnames = requiredVariableNames
            varnames = {'SatelliteID', ...
                'PositionX', 'PositionY', 'PositionZ', ...
                'VelocityX', 'VelocityY', 'VelocityZ', ...
                'AccelerationX', 'AccelerationY', 'AccelerationZ'};
        end
    end

    methods
        function [satPos,satVel,satID] = propagate(obj,t,navmsg)
            te = navmsg.Time;
            [gnssWeek, tow] = obj.getGNSSTime(t);
            [weekNum, toe] = obj.getGNSSTime(te);
            secondsPerWeek = 604800;
            dt = ((gnssWeek - weekNum)*secondsPerWeek) + (tow - toe);

            [satPos,satVel,satID] = glonassOrbitPropagation(dt,navmsg);
        end
    end
end

function [satPos,satVel,satID] = glonassOrbitPropagation(dt,navmsg)

% This uses the formulas defined in the GLONASS ICD Edition 5.1 2008.
% Section A.3.1.2.

km2m = 1e3;
x = km2m .* navmsg.PositionX;
y = km2m .* navmsg.PositionY;
z = km2m .* navmsg.PositionZ;
vx = km2m .* navmsg.VelocityX;
vy = km2m .* navmsg.VelocityY;
vz = km2m .* navmsg.VelocityZ;
ax = km2m .* navmsg.AccelerationX;
ay = km2m .* navmsg.AccelerationY;
az = km2m .* navmsg.AccelerationZ;

% Runge-Kutta integration.

% k1
[k1dx,k1dy,k1dz,k1dvx,k1dvy,k1dvz] = glonassSatelliteMotion(x,y,z,vx,vy,vz,ax,ay,az);
% k2
[k2dx,k2dy,k2dz,k2dvx,k2dvy,k2dvz] = glonassSatelliteMotion(x+k1dx.*dt/2,y+k1dy.*dt/2,z+k1dz.*dt/2, ...
    vx+k1dvx.*dt/2,vy+k1dvy.*dt/2,vz+k1dvz.*dt/2,ax,ay,az);
% k3
[k3dx,k3dy,k3dz,k3dvx,k3dvy,k3dvz] = glonassSatelliteMotion(x+k2dx.*dt/2,y+k2dy.*dt/2,z+k2dz.*dt/2, ...
    vx+k2dvx.*dt/2,vy+k2dvy.*dt/2,vz+k2dvz.*dt/2,ax,ay,az);
% k4
[k4dx,k4dy,k4dz,k4dvx,k4dvy,k4dvz] = glonassSatelliteMotion(x+k3dx.*dt,y+k3dy.*dt,z+k3dz.*dt, ...
    vx+k3dvx.*dt,vy+k3dvy.*dt,vz+k3dvz.*dt,ax,ay,az);

x = x + (dt./6).*(k1dx + 2.*k2dx + 2.*k3dx + k4dx);
y = y + (dt./6).*(k1dy + 2.*k2dy + 2.*k3dy + k4dy);
z = z + (dt./6).*(k1dz + 2.*k2dz + 2.*k3dz + k4dz);
vx = vx + (dt./6).*(k1dvx + 2.*k2dvx + 2.*k3dvx + k4dvx);
vy = vy + (dt./6).*(k1dvy + 2.*k2dvy + 2.*k3dvy + k4dvy);
vz = vz + (dt./6).*(k1dvz + 2.*k2dvz + 2.*k3dvz + k4dvz);

satPos = [x,y,z];
satVel = [vx,vy,vz];
satID = navmsg.SatelliteID;
end

function [dx,dy,dz,dvx,dvy,dvz] = glonassSatelliteMotion(x,y,z,vx,vy,vz,ax,ay,az)
% Differential equations describing GLONASS satellite motion in the
% PZ-90.02 coordinate system

% Constants
mu = 3.9860044e14; % m^3/s^2 - Gravitational constant
a_e = 6378136; % m - Semi-major axis of Earth
J_02 = 1082625.7e-9; % Second zonal harmonic of the geopotential
OmegaEDot = 7.292115e-5; % rad/s - Earth rotation rate

r = sqrt(x.^2 + y.^2 + z.^2);
dx = vx;
dy = vy;
dz = vz;
dvx = -mu./(r.^3).*x - 1.5.*J_02.^2.*(mu.*a_e.^2)./(r.^5).*x.*(1-5.*z.^2./(r.^2)) + OmegaEDot.^2.*x + 2.*OmegaEDot.*vy + ax;
dvy = -mu./(r.^3).*y - 1.5.*J_02.^2.*(mu.*a_e.^2)./(r.^5).*y.*(1-5.*z.^2./(r.^2)) + OmegaEDot.^2.*y + 2.*OmegaEDot.*vx + ay;
dvz = -mu./(r.^3).*z - 1.5.*J_02.^2.*(mu.*a_e.^2)./(r.^5).*z.*(1-5.*z.^2./(r.^2)) + az;
end