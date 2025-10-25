%This function is for internal use only. It may be removed in the future.
%
%CART2SPHCOVROT Rotation matrix from Cartesian coordinates to spherical
%coordinates for covariance matrices.
%   U = cart2sphcovrot(POS) returns the Jacobian matrix needed to transform
%   a covariance matrix given in Cartesian coordinates to a covariance
%   matrix in spherical coordinates. The result is a 3-by-3 matrix U, which
%   can be used in the similarity transformation:
%       SphCov = U * CartCov * U'
%   Where POS is a 3-element vector defining the Cartesian coordinates
%   where the covariance matrix is located with elements [X Y Z] and the
%   spherical 3-element position vector has elements [AZ EL RG], where AZ
%   and EL are in radians.
%
%   U = cart2sphcovrot(POS,VEL) returns the 4-by-6 Jacobian matrix that
%   transforms a 6-by-6 Cartesian covariance matrix representing the
%   covariance terms for a 6-element Cartesian position vector with
%   elements [X VX Y VY Z VZ] to a 4-by-4 spherical covariance matrix
%   representing the covariance terms for a 4-element spherical position
%   vector with elements [AZ EL RG RR].
%
% All the inputs must be real scalars.
% Class support: single, double.
% The return value is single if one of the inputs is single, otherwise it
% is double.
%
% Notes:
%   1. This function defines azimuth as measured counterclockwise from the
%      x-axis. This definition is consistent with cart2sph.
%   2. Azimuth (az) and elevation (el) are in radians.
%
%   Example:
%   % Convert spherical vector and covariance to Cartesian coordinates
%   az = deg2rad(10);
%   el = deg2rad(-3);
%   rg = 30;
%   sigmaAz = deg2rad(2);
%   sigmaEl = deg2rad(20);
%   sigmaRg = 5;
%
%   [x,y,z] = sph2cart(az,el,rg);
%   pos = [x;y;z]
%   U = matlabshared.tracking.internal.sph2cartcovrot(az,el,rg);
%   sphCov = diag([sigmaAz sigmaEl sigmaRg].^2);
%   cartCov = U * sphCov * U'
%
%   % Convert Cartesian covariance matrix back to spherical
%   U = matlabshared.tracking.internal.cart2sphcovrot(pos);
%   sphCov = U * cartCov * U'
%
% See also: sph2cart, cart2sph,
% matlabshared.tracking.internal.sph2cartcovrot
%
% internal function, no error checking is performed

%   Copyright 2020 The MathWorks, Inc.
function Uout = cart2sphcovrot(pos,vel)
%#codegen

validateattributes(pos, {'double', 'single'}, {'vector','real','numel',3},...
    'cart2sphcovrot', 'pos');

hasVel = nargin>1;
if hasVel
    validateattributes(vel, {'double', 'single'}, {'vector','real','numel',3},...
        'cart2sphcovrot', 'vel');
end

classToUse = class(pos);
measSize = 3+hasVel;
numStates = 6;
U = zeros(measSize, numStates, classToUse); % Up to 4 outputs (az, el, r, rr) by n states

% Compute the Jacobian for dSph/dCart
sensorpos = zeros(3,1,classToUse);
laxes = eye(3,3,classToUse);
A = matlabshared.tracking.internal.fusion.global2localcoordjac(pos(:),sensorpos,laxes);

% Keep angles in radians.
A(1:2,:) = deg2rad(A(1:2,:));

U(1:3,1:2:end) = A(1:3,1:3);
if hasVel
    cvstate = [pos(:) vel(:)]';
    cvstate = cvstate(:);
    sensorvel = sensorpos;
    U(end,:) = matlabshared.tracking.internal.fusion.rangeratejac...
        (cvstate,sensorpos,sensorvel,false); % call with flag = 0, CV model
    Uout = U;
else
    Uout = U(1:3,1:2:end); % Remove velocity entries
end

end

% LocalWords:  SphCov rg vel vy vz sph az el cartcovrot rr
