function U = sph2cartcovrot(az, el, r)
%SPH2CARTCOVROT Rotation matrix from spherical coordinates to Cartesian
%coordinates for covariance matrices.
% Calculates the rotation matrix needed to rotate a covariance matrix given
% in spherical coordinates, e.g. diag(sigmaAz^2, sigmaEl^2, sigmaR^2), to a
% covariance matrix in Cartesian coordinates. The result is matrix U, which
% can be used in the similarity transformation:
%   CartCov = U * SphCov * U'
%
% All the inputs must be real scalars.
% Class support: single, double. 
% The return value is single if one of the inputs is single, otherwise it
% is double.
%
% Notes: 
%   1. This function defines azimuth as measured counterclockwise from the
%      x-axis. This definition is consistent with cart2sph, but is
%      different from the one used in reference [1].
%   2. The azimuth (az) and elevation (el) must be in radians, as expected
%      in sph2cart.
%
% Reference:
%   [1] Use of Target-Oriented Process Noise In Tracking Maneuvering
%       Targets, J. Darren Parker and W. D. Blair, Weapons Systems
%       Department, Naval Surface Warfare Center, August 1992.
%
% See also: sph2cart, cart2sph

%   Copyright 2016 The MathWorks, Inc.

%#codegen

validateattributes(r, {'double', 'single'}, {'scalar','nonnegative', 'real'},...
    'sph2cartcovrot', 'r');
validateattributes(az, {'double', 'single'}, {'scalar', 'real'},...
    'sph2cartcovrot', 'az');
validateattributes(el, {'double', 'single'}, {'scalar', 'real'},...
    'sph2cartcovrot', 'el');

    cEl = cos(el);
    sEl = sin(el);
    cAz = cos(az);
    sAz = sin(az);
    U = [-r * cEl * sAz,          -r * sEl * cAz,   cEl * cAz; ...
          r * cEl * cAz,          -r * sEl * sAz,   cEl * sAz; ...
          0,                       r * cEl,         sEl];
end