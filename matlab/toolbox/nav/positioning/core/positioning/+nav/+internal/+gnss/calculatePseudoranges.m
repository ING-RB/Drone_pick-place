function [p, pdot, losVector] = calculatePseudoranges(satPos, satVel, recPos, recVel)
%CALCULATEPSEUDORANGES Compute pseudoranges and rates from satellite and
%   receiver positions and velocities
%
%   Inputs:
%     satPos - S-by-3 array of satellite positions in ECEF (m), where S is 
%              the number of satellites
%     satVel - S-by-3 array of satellite velocities in ECEF (m/s), where S 
%              is the number of satellites
%     recPos - 1-by-3 vector for receiver position in ECEF (m), where S is 
%              the number of satellites
%     recVel - 1-by-3 vector for receiver velocity in ECEF (m/s), where S 
%              is the number of satellites
%
%   Outputs:
%     p - S-element array of pseudoranges (m), where S is the number of 
%         satellites
%     pdot - S-element array of pseudorange rates (m/s), where S is the 
%            number of satellites
%     losVector - S-by-3 array of line-of-sight unit vectors from receiver 
%                 to satellite, where S is the number of satellites
%
%   NOTE
%       The outputs do not account for any error in the receiver clock. The
%       receiver clock bias and drift are assumed to be zero.
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

numSats = size(satPos, 1);
numAx = size(satPos, 2);

repRecPos = repmat(recPos, numSats, 1);
repRecVel = repmat(recVel, numSats, 1);

% Earth's rotation rate (rad/s).
[~, ~, ~, OmegaEDot] = fusion.internal.frames.wgs84ModelParams;
% Speed of light (m/s).
c = fusion.internal.ConstantValue.SpeedOfLight;

% Ranges without accounting for Earth's rotation.
posDiff = satPos - repRecPos;
rawRanges = vecnorm(posDiff, 2, 2);
losVector = posDiff ./ repmat(rawRanges, 1, numAx);

% Calculate pseudoranges with Earth's rotation.
% Use Technical Note: Derivation of Earth-Rotation Correction (Sagnac) and
% Analysis of the Effect of Receiver Clock Bias. However, use the full
% quadratic equation solution with the assumption that Rcorr << rawRanges.
Rcorr = (OmegaEDot/c) ...
   * (satPos(:,1).*repRecPos(:,2) - repRecPos(:,1).*satPos(:,2));
one = ones(numSats, 1, 'like', satPos);
e2 = one - ((OmegaEDot/c)^2*(satPos(:,1).*satPos(:,1) + satPos(:,2).*satPos(:,2)));
p = rawRanges./sqrt(e2) + Rcorr./e2;

deltaTimes = p ./ c;
rotECEF2ECI = repmat(eye(3), 1, 1, numel(deltaTimes));
rotECEF2ECI(1,1,:) = cos(OmegaEDot .* deltaTimes);
rotECEF2ECI(1,2,:) = sin(OmegaEDot .* deltaTimes);
rotECEF2ECI(2,1,:) = -sin(OmegaEDot .* deltaTimes);
rotECEF2ECI(2,2,:) = cos(OmegaEDot .* deltaTimes);

skewSymOmegaEDot = [        0, -OmegaEDot, 0; 
                    OmegaEDot,          0, 0;
                            0,          0, 0];
rotSatVel = zeros(numSats, 3);
% Rotate each satellite velocity by each corresponding rotation matrix.
for s = 1:numSats
    rotSatVelECEF = satVel(s,:) + (skewSymOmegaEDot * satPos(s,:).').';
    rotSatVel(s,:) = ( rotECEF2ECI(:,:,s) * rotSatVelECEF.' ).';
end

% Calculate pseudorange rate.
pdot = dot(losVector, rotSatVel - (repRecVel + (skewSymOmegaEDot * repRecPos.').'), 2);
end
