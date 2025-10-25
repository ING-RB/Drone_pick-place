%This function is for internal use only. It may be removed in the future.

%DLLA2NEDV Geodetic LLA to geocentric ECEF
% convert radian derivative about a degree LLA coordinate to NED 
%
%   Copyright 2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function nedv = dlla2nedv(dlla, lla)

lat = deg2rad(lla(:,1));       % phi       (radians)
alt = lla(:,3);                % height    (meters)

dlat = deg2rad(dlla(:,1));     % dphi      (radians/unit)
dlon = deg2rad(dlla(:,2));     % dlambda   (radians/unit)
dalt = dlla(:,3);              % dheight   (meters/unit)


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

% compute sin(2*lat) and cos(2*lat) and its derivatives
s2lat = sin(2*lat);

% compute sin(lat)^2 and its derivatives
slat2 = slat.^2;
dslat2 = s2lat .* dlat;

% get prime vertical radius of curvature N(lat) and its derivatives
u = 1 - e2 * slat2;
du = -e2 * dslat2;

N  = R .* u .^ -0.5;
dN  = R * -0.5 * u .^ -1.5 .* du;

% compute in cylindrical coordinates (rho,z)
% radial distance from polar axis (rho)
Npa = N + alt;
dNpa = dN + dalt;

rho = Npa .* clat;
drho = Npa .* dclat + dNpa .* clat;

% compute z and its derivatives
k = 1 - e2;
kNpa = k * N + alt;
dkNpa = k * dN + dalt;

% z = kNpa .* slat;
dz =kNpa .* dslat + dkNpa .* slat;

Vnorth = sqrt(dz.^2 + drho.^2);
Veast = rho .* dlon;
Vdown = dNpa;

nedv = [Vnorth, Veast, Vdown];