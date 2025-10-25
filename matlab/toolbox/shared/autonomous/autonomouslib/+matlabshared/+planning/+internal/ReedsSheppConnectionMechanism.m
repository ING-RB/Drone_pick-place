classdef ReedsSheppConnectionMechanism < matlabshared.planning.internal.ConnectionMechanism
%This class is for internal use only. It may be removed in the future.

%ReedsSheppConnectionMechanism ReedsShepp connection mechanism
%
%   Usage
%   -----
%   % Create a connection mechanism object
%   turningRadius         = 4;
%   numInterpolationSteps = 20;
%   connectionDistance    = 10;
%
%   connMech = matlabshared.planning.internal.ReedsSheppConnectionMechanism;
%   connMech.TurningRadius      = turningRadius;
%   connMech.NumSteps           = numInterpolationSteps;
%   connMech.ConnectionDistance = connectionDistance;
%
%   % Define two poses
%   % Note that heading must be radians.
%   fromPose = [4 4 pi/2];
%   toPose   = [6 4 pi/2];
%
%   % Find the ReedsShepp distance between two poses
%   d = distance(connMech, fromPose, toPose)
%
%   % Find waypoints between two poses along ReedsShepp curve.
%   poses = interpolate(connMech, fromPose, toPose)

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen

    properties
        TurningRadius = 4
        ReverseCost   = 1
    end

    properties (Constant)
        Exact = true;
        Name  = 'Reeds-Shepp';
    end

    methods
        %------------------------------------------------------------------
        function d = distance(this, from, to)

            d = matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppDistance(...
                from, to, this.TurningRadius, this.ReverseCost);
        end

        %------------------------------------------------------------------
        function poses = interpolate(this, from, to)

            poses = matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppInterpolate(...
                from, to, ...
                this.ConnectionDistance, this.NumSteps, ...
                this.TurningRadius, this.ReverseCost);
        end
    end
end
