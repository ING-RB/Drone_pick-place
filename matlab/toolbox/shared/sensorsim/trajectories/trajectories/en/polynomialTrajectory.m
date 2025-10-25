classdef polynomialTrajectory< matlab.System & matlab.system.mixin.FiniteSource & fusion.scenario.internal.mixin.PlatformTrajectory
    methods
        function out=polynomialTrajectory
        end

        function out=calculateCourse(~) %#ok<STOUT>
        end

        function out=fetchOrientationFromQuaternions(~) %#ok<STOUT>
        end

        function out=getPoses(~) %#ok<STOUT>
        end

        function out=isDoneImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
        end

        function out=lookupPose(~) %#ok<STOUT>
        end

        function out=resetImpl(~) %#ok<STOUT>
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
        end

        function out=setAutoBank(~) %#ok<STOUT>
        end

        function out=setAutoPitch(~) %#ok<STOUT>
        end

        function out=setClimbRate(~) %#ok<STOUT>
        end

        function out=setCourse(~) %#ok<STOUT>
        end

        function out=setCurrentPose(~) %#ok<STOUT>
        end

        function out=setGroundSpeed(~) %#ok<STOUT>
        end

        function out=setOrientation(~) %#ok<STOUT>
        end

        function out=setPiecewisePolynomials(~) %#ok<STOUT>
        end

        function out=setProperties(~) %#ok<STOUT>
        end

        function out=setReferenceFrame(~) %#ok<STOUT>
        end

        function out=setTimeOfArrival(~) %#ok<STOUT>
        end

        function out=setTypeAndParams(~) %#ok<STOUT>
        end

        function out=setVelocities(~) %#ok<STOUT>
        end

        function out=setWaypoints(~) %#ok<STOUT>
        end

        function out=setupImpl(~) %#ok<STOUT>
        end

        function out=setupInterpolants(~) %#ok<STOUT>
        end

        function out=setupOrientationInterpolant(~) %#ok<STOUT>
        end

        function out=setupWaypointParams(~) %#ok<STOUT>
        end

        function out=stepImpl(~) %#ok<STOUT>
        end

        function out=validateOrientationSizes(~) %#ok<STOUT>
        end

    end
    properties
        AutoBank;

        AutoPitch;

        ClimbRate;

        Course;

        GroundSpeed;

        Orientation;

        ReferenceFrame;

        SampleRate;

        SamplesPerFrame;

        TimeOfArrival;

        Velocities;

        Waypoints;

    end
end

 
%   Copyright 2022-2023 The MathWorks, Inc.

