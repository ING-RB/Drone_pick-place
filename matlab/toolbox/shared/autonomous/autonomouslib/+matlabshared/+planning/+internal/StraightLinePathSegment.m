classdef StraightLinePathSegment < matlabshared.planning.internal.PathSegmentInterface
    %This class is for internal use only. It may be removed in the future.
    
    %StraightLinePathSegment Internal Straight-Line path segment
    %   StraightLinePathSegment is an internal class representing a
    %   StraightLine path segment.
    %
    %   obj = matlabshared.planning.internal.StraightLinePathSegment(StraightLineConn, startPose, goalPose)
    %   creates a StraightLinePathSegment object for the optimal path between startPose and
    %   goalPose, using the connection object specified in StraightLine. StraightLine is an
    %   object of type matlabshared.planning.internal.StraightLineConnection.
    %   startPoint and goalPoint are specified as [x,y, theta].
    %
    %   obj = matlabshared.planning.internal.StraightLinePathSegment(...,motionLens)
    %   additionally specifies length of each motion.
    %
    %   matlabshared.planning.internal.StraightLinePathSegment properties:
    %   StartPoseInternal   - Internal start pose
    %   GoalPoseInternal    - Internal goal pose
    %   Length              - Length of path segment
    %
    %   matlabshared.planning.internal.StraightLinePathSegment methods:
    %   interpolateInternal - Interpolate along path segment
    %
    %   See also matlabshared.planning.internal.ReedsSheppPathSegment,
    %   matlabshared.planning.internal.DubinsPathSegment.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        %Length - Length of path segment.
        %   The length is specified as a scalar.
        Length
        
        %Direction - Traveling direction of the robot.
        Direction
    end
    
    properties (Access = protected)
        %StartPoseInternal
        %   Initial pose [x,y,theta]. theta is in radians.
        StartPoseInternal
        
        %GoalPoseInternal
        %   Goal pose [x,y,theta]. theta is in radians.
        GoalPoseInternal
    end
    
    methods
        
        function obj = StraightLinePathSegment(startPose, goalPose, varargin)
            
            obj.StartPoseInternal  = startPose;
            obj.GoalPoseInternal   = goalPose;
            
            if nargin == 2
                % Compute optimal path
                [cost, direction] = ...
                    matlabshared.planning.internal.StraightLineConnection.connectInternal(...
                    startPose, goalPose);
                
                obj.Length       = cost;
                obj.Direction    = direction;
                
            else
                narginchk(4,4);
                
                obj.Length       = varargin{1};
                obj.Direction    = varargin{2};
            end
        end
        
        function obj = set.StartPoseInternal(obj, startPose)
            
            matlabshared.planning.internal.validation.checkPose(startPose, 3, 'StartPose', '');
            obj.StartPoseInternal = double(startPose);
            obj.StartPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(obj.StartPoseInternal(3));
        end
        
        function obj = set.GoalPoseInternal(obj, goalPose)
            
            matlabshared.planning.internal.validation.checkPose(goalPose, 3, 'GoalPose', '');
            obj.GoalPoseInternal = double(goalPose);
            obj.GoalPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(obj.GoalPoseInternal(3));
        end
        
        function obj = set.Length(obj, length)
            
            validateattributes(length, {'single', 'double'}, ...
                {'scalar', 'finite', 'real', 'nonsparse', 'nonnegative'});
            
            obj.Length = double(length);
        end
        
        function obj = set.Direction(obj, direction)
            
            validateattributes(direction, {'single', 'double'}, ...
                {'scalar', 'finite', 'real', 'nonsparse'});
            
            if ~(direction==1)
                error(message('shared_autonomous:validation:unexpectedValues', ...
                    'Direction', '1'));
            end
            
            obj.Direction = double(direction);
        end
    end
    
    methods (Hidden)
        
        function [poses, directions] = interpolateInternal(obj, varargin)
            %Interpolate Sample the poses at the transitions (0 & at the
            %   end length) if user have not any specific sample lengths
            %   otherwise poses will be at transitions + samples lengths.
            
            % Check number of argument
            narginchk(1,2);
            
            samples = ...
                matlabshared.planning.internal.validation.interpolateInternalInputValidation(...
                obj.Length, obj.Length, varargin{:});
            
            start   = obj.StartPoseInternal;
            goal    = obj.GoalPoseInternal;
            
            % Intermediate orientation computation of path.
            theta = matlabshared.planning.internal.angleUtilities.wrapTo2Pi(...
                atan2(goal(2)-start(2),goal(1)-start(1)));
            
            thetaAll = theta*ones(numel(samples),1);
            
            %theta
            if theta ~= start(3)
                thetaAll = [start(3); thetaAll];
                samples  = [0; samples];
            end
            
            if theta ~= goal(3)
                thetaAll = [thetaAll; goal(3)];
                samples  = [samples; obj.Length];
            end
            
            % Compute the poses for given sample values
            poses       = nan(numel(samples),3);
            directions  = ones(numel(samples),1);
            poses(:,3)  = thetaAll;
            
            length = obj.Length;
            if length == 0
                length = 1;
            end
            poses(:,1:2) = start(1:2) + ((goal(1:2)-start(1:2)).*samples)./length;
        end
    end
end