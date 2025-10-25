%matlabshared.planning.internal.ReedsSheppPathSegment Internal ReedsShepp path segment
%   matlabshared.planning.internal.ReedsSheppPathSegment is an internal
%   class representing a ReedsShepp path segment.
%
%   obj = matlabshared.planning.internal.ReedsSheppPathSegment(reedsSheppConn, startPose, goalPose)
%   creates a ReedsSheppPathSegment object for the optimal path between startPose and
%   goalPose, using the connection object specified in rs. rs is an
%   object of type matlabshared.planning.internal.ReedsSheppConnection. startPose and
%   goalPose are specified as [x,y,theta], with theta in radians.
%
%   obj = matlabshared.planning.internal.ReedsSheppPathSegment(...,motionLens, motionTypes, motionDirs)
%   additionally specifies length, type and direction of each motion.
%
%   matlabshared.planning.internal.ReedsSheppPathSegment properties:
%   StartPoseInternal   - Internal start pose
%   GoalPoseInternal    - Internal goal pose
%   MinTurningRadius    - Internal ReedsShepp connection object
%   MotionLengths       - Length of each motion
%   MotionTypes         - Type of each motion
%   MotionDirections    - Direction of each motion
%   Length              - Length of path segment
%
%   matlabshared.planning.internal.ReedsSheppPathSegment methods:
%   interpolateInternal - Interpolate along path segment
%
%   See also matlabshared.planning.internal.DubinsPathSegment.

% Copyright 2018-2019 The MathWorks, Inc.

%#codegen
classdef (Hidden) ReedsSheppPathSegment < matlabshared.planning.internal.PathSegmentInterface
    
    properties (SetAccess = private)
        %MinTurningRadius
        %   Minimum turning radius, specified in world units. This
        %   corresponds to the turning radius of the circle at maximum
        %   steer.
        MinTurningRadius
        
        %MotionLengths
        % Length of each motion maneuver in the path segment in world
        % units, specified as a 5-element vector.
        MotionLengths
        
        %MotionDirections
        %   Direction of each motion, specified as a 3-element vector with
        %   values 1 or -1. 1 represents forward motion and -1 represents
        %   reverse motion.
        MotionDirections
    end
    
    properties (SetAccess = protected)
        %MotionTypes
        %   Type of each motion, specified as a 5 element vector, with each
        %   element representing a motion as described below:
        %
        %   ---------------------------------------------------------------
        %    Motion Maneuver  | Description
        %   ------------------|--------------------------------------------
        %     L               | Left turn at maximum steer
        %   ------------------|--------------------------------------------
        %     S               | Straight
        %   ------------------|--------------------------------------------
        %     R               | Right turn at maximum steer
        %   ------------------|--------------------------------------------
        %     N               | No motion
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
        %   'N'             | 4
        %   ---------------------------------------------------------------
        MotionTypesMap
    end
    
    methods
        %------------------------------------------------------------------
        function this = ReedsSheppPathSegment(rs, startPose, goalPose, varargin)
            
            validateattributes(rs, ...
                {'matlabshared.planning.internal.ReedsSheppConnection'}, ...
                {'scalar'},'ReedsSheppPathSegment','ConnectionMethod');
            
            this.MinTurningRadius   = rs.MinTurningRadius;
            this.StartPoseInternal  = startPose;
            this.GoalPoseInternal   = goalPose;
            
            if nargin<=3
                % Compute optimal path
                [motionLengths, motionTypes, ~, motionDirections] = ...
                    rs.connectInternal(startPose, goalPose);
                
                this.MotionLengths      = motionLengths';
                this.MotionTypes        = reshape(motionTypes, 1, []);     % Transpose is not supported in code generation
                this.MotionDirections   = motionDirections';
            else
                narginchk(6,6);
                
                this.MotionLengths      = varargin{1};
                this.MotionTypes        = varargin{2};
                this.MotionDirections   = varargin{3};
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
                'startPose', '');
            this.StartPoseInternal = startPose;
            this.StartPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(this.StartPoseInternal(3));
        end
        
        %------------------------------------------------------------------
        function this = set.GoalPoseInternal(this, goalPose)
            
            matlabshared.planning.internal.validation.checkPose(goalPose, 3, ...
                'goalPose', '');
            this.GoalPoseInternal = goalPose;
            this.GoalPoseInternal(3) = ...
                matlabshared.planning.internal.angleUtilities.wrapTo2Pi(this.GoalPoseInternal(3));
        end
        
        %------------------------------------------------------------------
        function this = set.MotionLengths(this, motionLengths)
            
            validateattributes(motionLengths, {'single', 'double'}, ...
                {'real', 'nonnegative', 'nonsparse', 'row', 'numel', 5}, ...
                '', 'motionLengths');
            
            this.MotionLengths = double(motionLengths);
        end
        
        %------------------------------------------------------------------
        function this = set.MotionTypes(this, motionTypes)
            
            validateattributes(motionTypes, {'cell','string'}, {'row', 'numel', 5});
            
            % 'N' means no operation & '' means path types has disabled.
            validMotionTypes = {'LRLNN', 'RLRNN', 'LRLRN', 'RLRLN', ...
                'LRSLN', 'RLSRN', 'LSRLN', 'RSLRN', 'LRSRN', 'RLSLN',...
                'RSRLN', 'LSLRN', 'LSRNN', 'RSLNN', 'LSLNN', 'RSRNN',...
                'LRSLR', 'RLSRL', ''};
            validatestring([motionTypes{:}], validMotionTypes, '', 'MotionTypes');
            this.MotionTypes = motionTypes;
        end
        
        %------------------------------------------------------------------
        function this = set.MotionDirections(this, motionDirs)
            
            validateattributes(motionDirs, {'single', 'double'}, ...
                {'real', 'nonsparse', 'row', 'numel', 5}, ...
                '', 'motionDirections');
            
            coder.internal.errorIf(~all(motionDirs==1 | motionDirs==-1), ...
                'shared_autonomous:validation:unexpectedValues', ...
                'MotionDirections', '1 or -1');
            
            this.MotionDirections = double(motionDirs);
        end
        
        %------------------------------------------------------------------
        function len = get.Length(this)
            
            len = sum(this.MotionLengths);
        end
        
        %------------------------------------------------------------------
        function motionTypesMap = get.MotionTypesMap(this)
            
            motionTypesMap                                  = ones(1, numel(this.MotionTypes));
            motionTypesMap(strcmp(this.MotionTypes, 'R'))   = 2;
            motionTypesMap(strcmp(this.MotionTypes, 'S'))   = 3;
            motionTypesMap(strcmp(this.MotionTypes, 'N'))   = 4;
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
            [poses, directions] = ...
                matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppInterpolateSegments(...
                this.StartPoseInternal, this.GoalPoseInternal, samples', this.MinTurningRadius,...
                this.MotionLengths, int32(this.MotionDirections), uint32(this.MotionTypesMap-1));
        end
        
    end
end