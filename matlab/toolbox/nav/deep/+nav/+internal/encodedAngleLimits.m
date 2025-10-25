function [cosThetaLimits, sinThetaLimits] = encodedAngleLimits(thetaBounds)
% This class is for internal use only. It may be removed in the future.

% encodedAngleLimits Computes the encoded angle limits.
%
% [COSTHETALIMITS, SINTHETALIMITS] = encodedAngleLimits(THETABOUNDS)
% Inputs:
%   THETABOUNDS    : [1,2] vector containing min, max values of angles
% Outputs:
%   COSTHETALIMITS : [1,2] vector containing min, max values of cosine of
%                    angles in the range of THETABOUNDS
%   SINTHETALIMITS : [1,2] vector containing min, max values of sine of
%                    angles in the range of THETABOUNDS
%
% Example
%  thetaBounds = [-pi/3, pi/3];
%  [sinThetaLimits, cosThetaLimits] = nav.internal.encodedAngleLimits(thetaBounds)
%       

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    thetaBounds = robotics.internal.wrapToPi(thetaBounds);
    sinThetaLimits = sort(sin(thetaBounds));
    cosThetaLimits = sort(cos(thetaBounds));


    %% Sin limits
    if thetaBounds(1) < pi/2 && thetaBounds(2) > pi/2
        sinThetaLimits(2) = 1;
    end

    if thetaBounds(1) < -pi/2 && thetaBounds(2) > -pi/2
        sinThetaLimits(1) = -1;
    end


    %% Cos limits
    if thetaBounds(1) < 0 && thetaBounds(2) > 0
        cosThetaLimits(2) = 1;
    end
