classdef (Abstract, Hidden) PathSegmentInterface
    %This class is for internal use only. It may be removed in the future.
    
    %PathSegmentInterface Interface for a path segment
    %
    %   See also matlabshared.planning.internal.DubinsPathSegment,
    %   matlabshared.planning.internal.ReedsSheppPathSegment.
    
    %#codegen
    
    % Copyright 2018 The MathWorks, Inc.
    
    
    properties (Abstract, Access = protected)
        %StartPoseInternal
        %   Internal representation of start pose
        StartPoseInternal
        
        %GoalPoseInternal
        %   Internal representation of goal pose
        GoalPoseInternal
    end
    
    properties (Abstract, Dependent, SetAccess = private)
        %StartPose
        %   Start pose, dependent on StartPoseInternal
        StartPose
        
        %GoalPose
        %   Goal pose, dependent on GoalPoseInternal
        GoalPose
        
        %Length
        %   Length of path segment, specified as a scalar.
        Length
    end
    
    methods (Abstract, Hidden)
        %interpolateInternal interpolate poses along path segment.
        [poses, directions] = interpolateInternal(this)
    end
    
    methods (Hidden)
        %------------------------------------------------------------------
        function isSequential = checkSequential(segments)
            %checkSequential - Check that an array of segments is sequential.
            %   tf = checkSequential(segments) returns true if an array of
            %   PathSegment objects, segments, are sequential.
            %
            %   Notes
            %   -----
            %   - Arrays with less than 2 elements return true.
            
            if numel(segments) < 2
                isSequential = true;
            else
                nextStart = [segments(2:end).StartPoseInternal];
                prevGoal  = [segments(1:end-1).GoalPoseInternal];
                
                % StartPose for (n+1)-th segment should match GoalPose for
                % n-th segment, within a tolerance. A tolerance is required
                % here because there could be conversions from deg to rad.
                numericTol = sqrt(eps(class(nextStart)));
                isSequential = all(abs(nextStart - prevGoal) < numericTol, 'all');
            end
        end
    end
end