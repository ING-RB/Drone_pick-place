classdef DubinsConnectionMechanism < matlabshared.planning.internal.ConnectionMechanism
    %This class is for internal use only. It may be removed in the future.
    
    %DubinsConnectionMechanism Dubins connection mechanism
    %
    %   Usage
    %   -----
    %   % Create a connection mechanism object
    %   turningRadius         = 4;
    %   numInterpolationSteps = 20;
    %   connectionDistance    = 10;
    %
    %   connMech = matlabshared.planning.internal.DubinsConnectionMechanism;
    %   connMech.TurningRadius      = turningRadius;
    %   connMech.NumSteps           = numInterpolationSteps;
    %   connMech.ConnectionDistance = connectionDistance;
    %
    %   % Define two poses
    %   % Note that heading must be radians.
    %   fromPose = [4 4 pi/2];
    %   toPose   = [6 4 pi/2];
    %
    %   % Find the Dubins distance between two poses
    %   d = connMech.distance(fromPose, toPose)
    %
    %   % Find intermediate poses between two poses along Dubins curve.
    %   poses = connMech.interpolate(fromPose, toPose)
    
    % Copyright 2017-2018 The MathWorks, Inc.   
    
    %#codegen
    
    properties
        TurningRadius = 4
    end
    
    properties (Constant)
        Exact = true;
        Name  = 'Dubins';
    end
    
    methods
        %------------------------------------------------------------------
        function d = distance(this, from, to)
            
            d = matlabshared.planning.internal.DubinsBuiltins.autonomousDubinsDistance(...
                from, to, this.TurningRadius);
        end
        
        %------------------------------------------------------------------
        function poses = interpolate(this, from, to)
            
            poses = matlabshared.planning.internal.DubinsBuiltins.autonomousDubinsInterpolate(...
                from, to, this.ConnectionDistance,  this.NumSteps, ...
                this.TurningRadius);
        end
    end
end
