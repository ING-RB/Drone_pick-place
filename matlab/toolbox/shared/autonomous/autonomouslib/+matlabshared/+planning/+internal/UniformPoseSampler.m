%matlabshared.planning.internal.UniformPoseSampler Uniform pose sampler with goal
%biasing.
%
%   Usage
%   -----
%   % Construct pose sampler
%   sampler = matlabshared.planning.internal.UniformPoseSampler(costmap);
%
%   % Configure costmap
%   sampler.configureCollisionChecker()
%
%   % Sample a pose
%   randPose = sampler.sample()
%
%   % Sample a goal bias
%   goalBias = sampler.sampleGoalBias()
%
%   Notes
%   -----
%   1. This class creates a sample buffer for pose and goal bias of length
%      equal the BufferSize property.
%   2. Precision of samples is determined by second input to the
%      constructor.

% Copyright 2017-2018 The MathWorks, Inc.
%#codegen
classdef UniformPoseSampler < matlabshared.planning.internal.EnforceScalarHandle
    
    properties (Access = private)
        %PoseBuffer
        %   Buffer of poses
        PoseBuffer
        
        %PoseIndex
        %   Index to next pose in pose buffer
        PoseIndex
        
        %GoalBiasBuffer
        %   Buffer of goal biases
        GoalBiasBuffer
        
        %GoalBiasIndex
        %   Index to next goal bias in goal bias buffer
        GoalBiasIndex
        
        %LowerLimits
        %   Lower limits of world
        LowerLimits
        
        %UpperLimits
        %   Upper limits of world
        UpperLimits
        
        %Costmap
        %   Costmap for collision checking
        Costmap
        
        %CollisionFree
        %   Indices of collision free poses
        CollisionFree
    end
    
    properties (Constant, Access = private)
        %BufferSize
        %   Size of buffer
        BufferSize = 5e3;
    end
    
    methods
        %------------------------------------------------------------------
        function this = UniformPoseSampler(costmap, precision)
            
            validateattributes(costmap, ...
                {'matlabshared.planning.internal.MapInterface'}, ...
                {'scalar'}, 'UniformPoseSampler', 'costmap');
            this.Costmap = costmap;
            
            worldExtent = costmap.MapExtent;
            
            % Use double-precision for pose sampling
            if nargin==1
                precision = 'double';
            else
                validateattributes(precision, {'char'}, ...
                    {'row','vector','nonempty'}, 'UniformPoseSampler', ...
                    'precision');
                validatestring(precision, {'single','double'}, ...
                    'UniformPoseSampler','precision');
            end
            this.LowerLimits = cast([worldExtent(1); worldExtent(3); 0], ...
                precision);
            this.UpperLimits = cast([worldExtent(2); worldExtent(4); 2*pi], ...
                precision);
            
            this.fillPoseBuffer();
            this.fillGoalBiasBuffer();
        end
        
        %------------------------------------------------------------------
        function reset(this)
            
            this.fillPoseBuffer();
            this.fillGoalBiasBuffer();
        end
        
        %------------------------------------------------------------------
        function configureCollisionChecker(this)
            
            this.checkForCollisions();
            
            % If there are no collision-free poses, attempt resampling
            if ~any(this.CollisionFree)
                this.attemptResampling();
            end
        end
        
        %------------------------------------------------------------------
        function [pose,collisionFree] = sample(this)
            
            collisionFree = this.CollisionFree(this.PoseIndex);
            
            if collisionFree
                pose = (this.PoseBuffer(:, this.PoseIndex)).';
            else
                pose = nan(3,1,'like',this.PoseBuffer);
            end
            
            this.PoseIndex = this.PoseIndex + 1;
            
            if this.PoseIndex > this.BufferSize
                this.fillPoseBuffer();
                
                % If there are no collision-free poses, attempt resampling
                if ~any(this.CollisionFree)
                    this.attemptResampling();
                end
            end
        end
        
        %------------------------------------------------------------------
        function goalBias = sampleGoalBias(this)
            
            goalBias = this.GoalBiasBuffer(this.GoalBiasIndex);
            
            this.GoalBiasIndex = this.GoalBiasIndex + 1;
            
            if this.GoalBiasIndex > this.BufferSize
                this.fillGoalBiasBuffer();
            end
        end
        
        %------------------------------------------------------------------
        function pose = sampleCollisionFree(this)
            
            pose = nan(3,1,'like',this.PoseBuffer);
            collisionFree = false;
            while ~collisionFree
                
                [pose,collisionFree] = this.sample();
            end
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function fillPoseBuffer(this)
            
            % MATLAB Coder does not support implicit scalar expansion, so
            % use bsxfun instead. There is a slight performance difference
            % because of the need for cascaded bsxfun calls.
            if isempty(coder.target)
                this.PoseBuffer = this.LowerLimits + ...
                    (this.UpperLimits - this.LowerLimits) .* ...
                    rand(3, this.BufferSize, 'like', this.LowerLimits);
            else
                this.PoseBuffer = bsxfun(@plus, this.LowerLimits, ...
                    bsxfun(@times, (this.UpperLimits - this.LowerLimits), ...
                    rand(3, this.BufferSize, 'like', this.LowerLimits)));
            end
            
            % Pose buffer has been replaced. Check for collisions.
            this.checkForCollisions();
            
            this.PoseIndex = 1;
        end
        
        %------------------------------------------------------------------
        function fillGoalBiasBuffer(this)
            
            this.GoalBiasBuffer = rand(1, this.BufferSize, 'like', this.LowerLimits);
            
            this.GoalBiasIndex = 1;
        end
        
        %------------------------------------------------------------------
        function checkForCollisions(this)
            
            if ~isempty(this.Costmap)
                vehiclePoses    = this.PoseBuffer.';
                throwError      = false;
                
                this.CollisionFree = checkFreePoses(this.Costmap, ...
                    vehiclePoses, throwError);
            end
        end
        
        %------------------------------------------------------------------
        function attemptResampling(this)
            
            maxAttempts = 4;
            
            % NumAttempts is already 1 because we have already made one
            % attempt before invoking this routine.
            numAttempts = 1;
            
            noFreePoses = true;
            while noFreePoses && numAttempts < maxAttempts
                % Try again
                this.fillPoseBuffer();
                
                % Check if any free poses were found
                noFreePoses = ~any(this.CollisionFree);
                
                % Increment number of attempts made
                numAttempts = numAttempts + 1;
            end
            
            coder.internal.errorIf(noFreePoses, ...
                'shared_autonomous:pathPlannerRRT:noCollisionFreeSamples', ...
                numAttempts*this.BufferSize);
            
        end
    end
end
