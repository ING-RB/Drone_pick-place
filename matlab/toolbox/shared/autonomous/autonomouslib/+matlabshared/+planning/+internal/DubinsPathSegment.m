classdef (Hidden) DubinsPathSegment < matlabshared.planning.internal.PathSegmentInterface
    %This class is for internal use only. It may be removed in the future.
    
    %DubinsPathSegment Internal Dubins path segment
    %
    %   obj = matlabshared.planning.internal.DubinsPathSegment(dubinsConn, startPose, goalPose)
    %   creates a DubinsPathSegment object for the optimal path between startPose and
    %   goalPose, using the connection object specified in dubins. dubins is an
    %   object of type matlabshared.planning.internal.DubinsConnection. startPose
    %   and goalPose are specified as [x,y,theta], with theta in radians.
    %
    %   obj = matlabshared.planning.internal.DubinsPathSegment(...,motionLens, motionTypes, motionDirs)
    %   additionally specifies length, type and direction of each motion.
    %
    %   matlabshared.planning.internal.DubinsPathSegment properties:
    %   StartPoseInternal   - Internal start pose
    %   GoalPoseInternal    - Internal goal pose
    %   MinTurningRadius    - Minimum turning radius
    %   MotionLengths       - Length of each motion
    %   MotionTypes         - Type of each motion
    %   Length              - Length of path segment
    %
    %   matlabshared.planning.internal.DubinsPathSegment methods:
    %   interpolateInternal - Interpolate along path segment
    %
    %   See also matlabshared.planning.internal.ReedsSheppPathSegment.
    
    %#codegen
    
    % Copyright 2018-2019 The MathWorks, Inc.
    
    properties (SetAccess = private)
        %MinTurningRadius
        %   Minimum turning radius, specified in world units. This
        %   corresponds to the turning radius of the circle at maximum
        %   steer.
        MinTurningRadius
        
        %MotionLengths
        % Length of each motion maneuver in the path segment in world units,
        % specified as a 3-element vector.
        MotionLengths
    end
    
    properties (SetAccess = protected)
        %MotionTypes
        %   Type of each motion, specified as a 3-element vector, with each
        %   element representing a motion as described below:
        %
        %   ---------------------------------------------------------------
        %    Motion Maneuver | Description
        %   -----------------|---------------------------------------------
        %     L              | Left turn at maximum steer
        %   -----------------|---------------------------------------------
        %     S              | Straight
        %   -----------------|---------------------------------------------
        %     R              | Right turn at maximum steer
        %   ---------------------------------------------------------------
        MotionTypes
    end
    
    properties (Dependent, SetAccess = private)
        %Length
        %   Length of path segment, specified as a scalar.
        Length
    end
    
    properties (Access = protected)
        %StartPoseInternal
        %   Initial pose [x,y,theta]. theta is in radians.
        StartPoseInternal
        
        %GoalPoseInternal
        %   Goal pose [x,y,theta]. theta is in radians.
        GoalPoseInternal
    end
    
    properties (Dependent, Access = private)
        %MotionTypesMap
        %   Mapping from motion type to integer.
        %   ---------------------------------------------------------------
        %   Motion Maneuver | Mapping Value
        %   ---------------------------------------------------------------
        %   'L'             | 1
        %   ---------------------------------------------------------------
        %   'R'             | 2
        %   ---------------------------------------------------------------
        %   'S'             | 3
        %   ---------------------------------------------------------------
        MotionTypesMap
    end
    
    methods
        %------------------------------------------------------------------
        function this = DubinsPathSegment(dubins, startPose, goalPose, varargin)
            
            validateattributes(dubins, ...
                {'matlabshared.planning.internal.DubinsConnection'}, ...
                {'scalar'}, 'DubinsPathSegment', 'ConnectionMethod');
            
            this.MinTurningRadius   = dubins.MinTurningRadius;
            this.StartPoseInternal  = startPose;
            this.GoalPoseInternal   = goalPose;
            
            if nargin == 3
                % Compute optimal path
                [motionLengths, motionTypes] = ...
                    dubins.connectInternal(startPose, goalPose);
                
                this.MotionLengths      = motionLengths.';
                this.MotionTypes        = reshape(motionTypes,1,[]);       % Transpose is not supported for code generation
            else
                narginchk(5,5);
                
                this.MotionLengths      = varargin{1};
                this.MotionTypes        = varargin{2};
            end
        end
        
        %------------------------------------------------------------------
        function this = set.MinTurningRadius(this, radius)
            
            validateattributes(radius, {'single', 'double'}, ...
                {'real', 'nonsparse', 'positive', 'finite', 'scalar'});
            
            this.MinTurningRadius = double(radius);
        end
        
        %------------------------------------------------------------------
        function this = set.StartPoseInternal(this, startPose)
            
            matlabshared.planning.internal.validation.checkPose(startPose, 3, ...
                'StartPose', '');
            this.StartPoseInternal = startPose;
            this.StartPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(this.StartPoseInternal(3));
        end
        
        %------------------------------------------------------------------
        function this = set.GoalPoseInternal(this, goalPose)
            
            matlabshared.planning.internal.validation.checkPose(goalPose, 3, ...
                'GoalPose', '');
            this.GoalPoseInternal = goalPose;
            this.GoalPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(this.GoalPoseInternal(3));
        end
        
        %------------------------------------------------------------------
        function this = set.MotionLengths(this, motionLengths)
            
            validateattributes(motionLengths, {'double'}, ...
                {'real', 'nonnegative', 'nonsparse', 'row', 'numel', 3}, ...
                '', 'MotionLengths');
            this.MotionLengths = double(motionLengths);
        end
        
        %------------------------------------------------------------------
        function this = set.MotionTypes(this, motionTypes)
            
            validateattributes(motionTypes, {'cell','string'}, {'row', 'numel', 3});
            
            % '' means path types has disabled.
            allPathTypes = matlabshared.planning.internal.DubinsConnection.AllPathTypes;
            
            validMotionTypes = coder.nullcopy(cell(1, numel(allPathTypes)+1));
            for n = 1 : numel(allPathTypes)
                validMotionTypes{n} = allPathTypes{n};
            end
            validMotionTypes{n+1} = '';
            
            validatestring([motionTypes{:}], validMotionTypes, '', 'MotionTypes');
            this.MotionTypes = motionTypes;
        end
        
        %------------------------------------------------------------------
        function len = get.Length(this)
            
            len = sum(this.MotionLengths);
        end
        
        %------------------------------------------------------------------
        function motionTypesMap = get.MotionTypesMap(this)
            
            motionTypesMap                                  = uint32(ones(1, numel(this.MotionTypes)));
            motionTypesMap(strcmp(this.MotionTypes, 'R'))   = 2;
            motionTypesMap(strcmp(this.MotionTypes, 'S'))   = 3;
        end
    end
    
    methods (Hidden)
        %------------------------------------------------------------------
        function [poses, directions] = interpolateInternal(this, varargin)
            % interpolate Sample the poses
            
            % Check number of arguments
            narginchk(1,4);
            
            % Check path is feasible or not.
            if any(isnan(this.MotionLengths)) || isempty(this.MotionTypes{1})
                poses       = zeros(0,3);
                directions  = zeros(0,1);
                return;
            end
            
            samples = matlabshared.planning.internal.validation.interpolateInternalInputValidation(...
                this.MotionLengths, this.Length, varargin{:});
            
            % Compute the poses for given sample values
            poses = ...
                matlabshared.planning.internal.DubinsBuiltins.autonomousDubinsInterpolateSegments(...
                this.StartPoseInternal, this.GoalPoseInternal, samples',...
                this.MinTurningRadius, this.MotionLengths, uint32(this.MotionTypesMap-1));
            directions = ones(numel(samples),1);
        end
    end
end
