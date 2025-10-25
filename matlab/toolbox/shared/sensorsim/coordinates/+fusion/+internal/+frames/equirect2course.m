function radCourse = equirect2course(projCourse, lla)
%EQUIRECT2COURSE converts equirectangular geodetic projected course to NED
%
%   projectedCourse - Nx1 vector where equirectangular course is
%                     expressed in radians clockwise from "North"
%
%   LLA - Nx3 matrix where first column is latitude (degrees), second
%         column is longitude (degrees), and altitude (meters).
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2023 The MathWorks, Inc.

%#codegen


lat = deg2rad(lla(:,1));       % phi       (radians)

% compute intermediates of latitude
slat = sin(lat);
clat = cos(lat);
s2lat = sin(2*lat);
slat2 = slat.^2;

% flattening and squared eccentricity
f  = 1/298.257223563;
e2 = f * (2 - f);

% equatorial radius
R =  6378137;

% get prime vertical radius of curvature N(lat) and its derivative.
u = 1 - e2 * slat2;
N  = R .* u .^ -0.5;

dNbydlat = R * -0.5 * u .^ -1.5 .* -e2 .* s2lat;

% radial distance from polar axis (rho)
rho = N .* clat;
k = 1 - e2;

% fetch unit direction vector
dlat = cos(projCourse);
dlon = sin(projCourse);

% transform to equirectangular projection derivatives
Vnorth = dlat .* (k * (N .*  clat  + dNbydlat .* slat) .* clat ...
                    - (N .* -slat  + dNbydlat .* clat) .* slat);
Veast = dlon .* rho;

% report back actual course in radians
radCourse = atan2(Veast,Vnorth);