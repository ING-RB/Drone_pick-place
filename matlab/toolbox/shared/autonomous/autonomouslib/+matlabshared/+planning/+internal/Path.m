%matlabshared.planning.internal.Path Internal path
%   matlabshared.planning.internal.Path is an internal class representing a
%   path, composed of a sequence of path segments.
%
%   obj = matlabshared.planning.internal.Path(segments) creates a path
%   object from the array of PathSegment objects, segments.
%
%   See also matlabshared.planning.internal.DubinsPathSegment,
%   matlabshared.planning.internal.ReedsSheppPathSegment.
    

% Copyright 2018 The MathWorks, Inc.

%#codegen
classdef (Hidden) Path 
    
    properties (SetAccess = protected)
        %PathSegments
        %   Segments along the path, specified as an array of
        %   DubinsPathSegment or ReedsSheppPathSegment objects.
        PathSegments
    end
    
    properties (Dependent, SetAccess = private)
        %Length
        %   Length of the path.
        Length
    end
    
    properties (Abstract, Dependent, SetAccess = private)
        %StartPose
        %   Start pose, dependent on StartPoseInternal
        StartPose
        
        %GoalPose
        %   Goal pose, dependent on GoalPose Internal
        GoalPose
    end
    
    methods
        %------------------------------------------------------------------
        function [poses, directions] = interpolate(this, varargin)
            
            narginchk(1,2);
            
            % Handle empty path (no path segments)
            if isempty(this.PathSegments)
                poses       = zeros(0,3,'like',this.StartPose);
                directions  = zeros(0,1,'like',this.StartPose);
                return;
            end
            
            if nargin==2
                lengths = varargin{1};
                validateattributes(lengths, {'single','double'}, ...
                    {'vector', 'finite', 'real', 'nonsparse', 'nonnegative',...
                    'increasing', '<=', this.Length}, 'interpolate', 'samples');
            else
                lengths = [];
            end
            
            if ~isempty(coder.target)
                [poses,directions] = interpolateCG(this, lengths);
                return;
            end
            
            % Add transition samples, saturating at length
            transitionSamples = cumsum([this.PathSegments.MotionLengths]);
            samplesAll = min(unique([lengths(:); transitionSamples(:)]), this.Length);
            
            % Map requested samples to the respective path segment
            
            accumLengths = cumsum([0, this.PathSegments.Length]);
            segmentIndex = discretize(samplesAll, accumLengths);
            
            % Initialize poses and directions
            poses       = zeros(0,3,'like',this.StartPose);
            directions  = zeros(0,1);
            
            % Interpolate along each path segment, and concatenate the results
            excludeStart        = true;
            addTransitions      = false;
            for n = 1 : numel(this.PathSegments)
                % Find the samples belonging to the n-th segment
                segmentSamples = samplesAll(segmentIndex==n) - accumLengths(n);
                
                % Use of cumsum can cause precision differences for sample
                % lengths, so saturate segmentSamples at segment length
                segmentSamples = min(segmentSamples, this.PathSegments(n).Length);
                
                % Interpolate along n-th segment
                [segmentPoses, segmentDirections] = interpolateInternal(...
                    this.PathSegments(n), segmentSamples, n>1 && excludeStart, addTransitions);
                
                % Concatenate
                poses       = [poses; segmentPoses];            %#ok<AGROW>
                directions  = [directions; segmentDirections];  %#ok<AGROW>
            end
        end
    end
    
    methods
        %------------------------------------------------------------------
        function this = Path(segments)
            
            this.PathSegments = segments;
        end
        
        %------------------------------------------------------------------
        function len = get.Length(this)
            
            if isempty(this.PathSegments)
                len = 0;
            else
                len = sum( [this.PathSegments.Length] );
            end
        end
        
        %------------------------------------------------------------------
        function this = set.PathSegments(this, segments)
            
            validateattributes(segments, ...
                {'matlabshared.planning.internal.PathSegmentInterface'}, ...
                {},'','PathSegments');
            
            isSequential = segments.checkSequential();
            
            coder.internal.errorIf(~isSequential, ...
                'shared_autonomous:path:expectedSequentialPathSegments');
            
            this.PathSegments = segments;
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function [poses,directions] = interpolateCG(this, lengths)
            
            numSegments = numel(this.PathSegments);
            numMotions  = numel(this.PathSegments(1).MotionLengths);
            
            transitionSamples = coder.nullcopy(...
                zeros(1, numSegments*numMotions, ...
                'like', this.PathSegments(1).MotionLengths) );
            
            t = 1;
            accum = 0;
            for s = 1 : numSegments
                motionLens = this.PathSegments(s).MotionLengths;
                
                for m = 1 : numMotions
                    transitionSamples(t) = accum + motionLens(m);
                    accum = transitionSamples(t);
                    t = t + 1;
                end
            end
            
            % Add transition samples, saturating at length
            if ~isempty(lengths)
                samplesAll = min(unique([lengths(:); transitionSamples(:)]), this.Length);
            else
                samplesAll = min(unique(transitionSamples(:)), this.Length);
            end
            
            numSegments = numel(this.PathSegments);
            accumLengths = coder.nullcopy( zeros(1+numSegments,1,'like', this.PathSegments(1).Length) );
            accumLengths(1) = 0;
            for s = 1 : numSegments
                accumLengths(s+1) = accumLengths(s) + this.PathSegments(s).Length;
            end
            
            segmentIndex = discretizecg(samplesAll, accumLengths);
            
            % Initialize poses and directions
            poses       = zeros(0,3,'like',this.StartPose);
            directions  = zeros(0,1);
            
            % Interpolate along each path segment, and concatenate the results
            excludeStart        = true;
            addTransitions      = false;
            for n = 1 : numel(this.PathSegments)
                % Find the samples belonging to the n-th segment
                segmentSamples = samplesAll(segmentIndex==n) - accumLengths(n);
                
                % Use of cumsum can cause precision differences for sample
                % lengths, so saturate segmentSamples at segment length
                segLen = this.PathSegments(n).Length;
                for s = 1 : numel(segmentSamples)
                    segmentSamples(s) = min(segmentSamples(s), segLen);
                end
                
                % Interpolate along n-th segment
                [segmentPoses, segmentDirections] = interpolateInternal(...
                    this.PathSegments(n), segmentSamples, n>1 && excludeStart, addTransitions);
                
                % Concatenate
                poses       = [poses; segmentPoses];            %#ok<AGROW>
                directions  = [directions; segmentDirections];  %#ok<AGROW>
            end
        end
    end
end

function bins = discretizecg(x, edges)
% Code generation implementation for discretize function. Remove this when 
% g1849092 is actioned.
%
% Note: This implementation assumes that all the data in x is within bin
%       limits.
bins = coder.nullcopy(zeros(size(x,1),size(x,2),'like',x));

numEdges = numel(edges)-1;
for n = 1 : numel(x)
    for e = 1 : numEdges-1
        % An element x(n) falls into the e-th bin if 
        %   edges(e) <= x(n) < edges(e+1)
        if x(n) >= edges(e) && x(n) < edges(e+1)
            bins(n) = e;
            break;
        end
    end
    % For the last bin, include the right-edge as well.
    if x(n) >= edges(numEdges)
        bins(n) = numEdges;
    end
end
end