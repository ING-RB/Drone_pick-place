function [posECEF, velECEF, accECEF, jerECEF, ...
          velNED, accNED, jerNED] = lla2derivs(lla, dlla, ddlla, dddlla)
%LLA2ECEFDERIVS converts geodetic coordinates and their derivatives into
%   Cartesian coordinates in ECEF 
%
%   LLA - Nx3 matrix where first column is latitude (degrees), second
%         column is longitude (degrees), and altitude (meters).
%
%   Remaining arguments are derivatives of LLA with respect to some
%   arbitrary independent variable of some arbitrary unit.  (usually
%   time or distance traveled)
%
%   DLLA   - 1st derivative of LLA 
%   DDLLA  - 2nd derivative of LLA
%   DDDLLA - 3rd derivative of LLA
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

lat = deg2rad(lla(:,1));       % phi       (radians)
lon = deg2rad(lla(:,2));       % lambda    (radians)
alt = lla(:,3);                % height    (meters)

dlat = deg2rad(dlla(:,1));     % dphi      (radians/unit)
dlon = deg2rad(dlla(:,2));     % dlambda   (radians/unit)
dalt = dlla(:,3);              % dheight   (meters/unit)

ddlat = deg2rad(ddlla(:,1));   % ddphi     (radians/unit^2)
ddlon = deg2rad(ddlla(:,2));   % ddlambda  (radians/unit^2)
ddalt = ddlla(:,3);            % ddheight  (meters/unit^2)

dddlat = deg2rad(dddlla(:,1)); % dddphi    (radians/unit^3)
dddlon = deg2rad(dddlla(:,2)); % dddlambda (radians/unit^3)
dddalt = dddlla(:,3);          % dddheight (meters/unit^3)

% flattening and squared eccentricity
f  = 1/298.257223563;
e2 = f * (2 - f);

% equatorial radius
R =  6378137;

% compute sin/cos of longitude and its derivatives
slat = sin(lat);
clat = cos(lat);

dslat =  clat .* dlat;
dclat = -slat .* dlat;

ddslat =  clat .* ddlat + dclat .* dlat;
ddclat = -slat .* ddlat - dslat .* dlat;

dddslat =  clat .* dddlat + 2 * dclat .* ddlat + ddclat .* dlat;
dddclat = -slat .* dddlat - 2 * dslat .* ddlat - ddslat .* dlat;

% compute sin(2*lat) and cos(2*lat) and its derivatives
s2lat = sin(2*lat);
c2lat = cos(2*lat);

ds2lat =  2 * c2lat .* dlat;
dc2lat = -2 * s2lat .* dlat;

dds2lat = 2 * c2lat .* ddlat + 2 * dc2lat .* dlat;

% compute sin(lat)^2 and its derivatives
slat2 = slat.^2;
dslat2 = s2lat .* dlat;
ddslat2 = s2lat .* ddlat + ds2lat .* dlat;
dddslat2 = s2lat .* dddlat + 2 * ds2lat .* ddlat + dds2lat .* dlat;

% compute sin/cos of longitude and their derivatives
slon = sin(lon);
clon = cos(lon);

dslon = clon .* dlon;
dclon = -slon .* dlon;

ddslon =  clon .* ddlon + dclon .* dlon;
ddclon = -slon .* ddlon - dslon .* dlon;

dddslon =  clon .* dddlon + 2 * dclon .* ddlon + ddclon .* dlon;
dddclon = -slon .* dddlon - 2 * dslon .* ddlon - ddslon .* dlon;

% get prime vertical radius of curvature N(lat) and its derivatives
u = 1 - e2 * slat2;
du = -e2 * dslat2;
ddu = -e2 * ddslat2;
dddu = -e2 * dddslat2;

N  = R .* u .^ -0.5;
dN  = R * -0.5 * u .^ -1.5 .* du;
ddN = R * (-0.5 * u .^ -1.5 .* ddu + 0.75 * u .^ -3.5 .* du .* du);
dddN = R * (-0.5 * u .^ -1.5 .* dddu + 0.75 * u .^ -3.5 .* du .* ddu + ...
              0.75 * u .^ -3.5 .* du .* ddu + ...
             (0.75 * u .^ -3.5 .* ddu - 2.625 * u .^ -4.5 .* du .* du) .* du);

% compute in cylindrical coordinates (rho,z)
% radial distance from polar axis (rho)
Npa = N + alt;
dNpa = dN + dalt;
ddNpa = ddN + ddalt;
dddNpa = dddN + dddalt;

rho = Npa .* clat;
drho = Npa .* dclat + dNpa .* clat;
ddrho = Npa .* ddclat + 2 * dNpa .* dclat + ddNpa .* clat;
dddrho = Npa .* dddclat + 3 * (dNpa .* ddclat + ddNpa .* dclat) + dddNpa .* clat;

% compute z and its derivatives
k = 1 - e2;
kNpa = k * N + alt;
dkNpa = k * dN + dalt;
ddkNpa = k * ddN + ddalt;
dddkNpa = k * dddN + dddalt;

z = kNpa .* slat;
dz =kNpa .* dslat + dkNpa .* slat;
ddz = kNpa .* ddslat + 2 * dkNpa .* dslat + ddkNpa .* slat;
dddz = kNpa .* dddslat + 3 * (dkNpa .* ddslat + ddkNpa .* dslat) + dddkNpa .* slat;

% Convert from rho and longitude to (x,y) and compute its derivatives
x = rho .* clon;
y = rho .* slon;

dx = rho .* dclon + drho .* clon;
dy = rho .* dslon + drho .* slon;

ddx = rho .* ddclon + 2 * drho .* dclon + ddrho .* clon;
ddy = rho .* ddslon + 2 * drho .* dslon + ddrho .* slon;

dddx = rho .* dddclon + 3 * (drho .* ddclon + ddrho .* dclon) + dddrho .* clon;
dddy = rho .* dddslon + 3 * (drho .* ddslon + ddrho .* dslon) + dddrho .* slon;

% build outupt Nx3 matrices
posECEF = [x, y, z];
velECEF = [dx, dy, dz];
accECEF = [ddx, ddy, ddz];
jerECEF = [dddx, dddy, dddz];

% compute vel, acc, and jerk in NED frame
% Vnorth = dz .* clat - drho .* slat;
% Veast = rho .* dlon;
% Vdown = -dalt;

Vin    =  clon .* dx + slon .* dy;
Veast  = -slon .* dx + clon .* dy;
Vnorth = -slat .* Vin + clat .* dz;
Vdown  = -clat .* Vin - slat .* dz;

dVin    =  clon .* ddx + slon .* ddy;
dVeast  = -slon .* ddx + clon .* ddy;
dVnorth = -slat .* dVin + clat .* ddz;
dVdown  = -clat .* dVin - slat .* ddz;

ddVin    =  clon .* dddx + slon .* dddy;
ddVeast  = -slon .* dddx + clon .* dddy;
ddVnorth = -slat .* ddVin + clat .* dddz;
ddVdown  = -clat .* ddVin - slat .* dddz;

velNED = [Vnorth, Veast, Vdown];
accNED = [dVnorth, dVeast, dVdown];
jerNED = [ddVnorth, ddVeast, ddVdown];