classdef ResamplingPolicy < handle
    %ResamplingPolicy Create resampling policy for particle filter
    %   After a sensor measurement is incorporated in the particle
    %   filter during the correction stage, a resampling of all particles
    %   might occur.
    %
    %   The settings in this object determine if and when resampling should
    %   occur.
    %
    %   POLICY = matlabshared.tracking.internal.ResamplingPolicy creates a
    %   ResamplingPolicy object POLICY. Its properties can be modified to control
    %   when resampling should be triggered.
    %
    %
    %   ResamplingPolicy properties:
    %       TriggerMethod             - Method used for determining if resampling should be triggered
    %       SamplingInterval          - Fixed interval between resampling
    %       MinEffectiveParticleRatio - Minimum desired ratio of effective to total particles
    %
    %
    %   Example:
    %
    %      % Create policy object
    %      pol = matlabshared.tracking.internal.ResamplingPolicy
    %
    %      % Change trigger mode to interval-based triggering
    %      pol.TriggerMethod = 'interval'
    %
    %      % Trigger resampling every third step
    %      pol.SamplingInterval = 3
    %
    %
    %   References:
    %
    %   [1] M.S. Arulampalam, S. Maskell, N. Gordon, T. Clapp, "A tutorial on
    %       particle filters for online nonlinear/non-Gaussian Bayesian tracking,"
    %       IEEE Transactions on Signal Processing, vol. 50, no. 2, pp. 174-188,
    %       Feb 2002
    %   [2] Z. Chen, "Bayesian filtering: From Kalman filters to particle filters,
    %       and beyond," Statistics, vol. 182, no. 1, pp. 1-69, 2003
    
    %   Copyright 2015-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %TriggerMethod - Method used for determining if resampling should be triggered
        %   Possible choices are 'ratio' and 'interval'. In the 'interval'
        %   method, the resampling is triggered in regular intervals, whereas
        %   the 'ratio' method triggers resampling based on the ratio of
        %   effective to total particles.
        %
        %   Default: 'ratio'
        TriggerMethod
        
        %SamplingInterval - Fixed interval between resampling
        %   Determines during which correction steps the resampling is
        %   executed. For example, if the value is 2, the resampling
        %   is executed every second correction step. If the value is Inf,
        %   the resampling is never executed.
        %
        %   This property only applies when the TriggerMethod is set to
        %   'interval'.
        %
        %   Default: 1
        SamplingInterval
        
        %MinEffectiveParticleRatio - The minimum desired ratio of effective to total particles
        %   The effective number particle of particles is a measure of how
        %   well the current set of particles approximates the posterior
        %   distribution. If the ratio of effective particles to total particles
        %   falls below MinEffectiveParticleRatio, a resampling step is
        %   triggered.
        %
        %   This property only applies when the TriggerMethod is set to
        %   'ratio'.
        %
        %   Default: 0.5 (unitless)
        MinEffectiveParticleRatio
    end
    
    %% Internal Storage Properties
    % These are used for storing data of dependent properties and to avoid
    % order-dependency in initialization.
    properties (Access = protected)
        %InternalTriggerMethod - Internal storage for trigger method
        %   This is user-exposed through the TriggerMethod property.
        InternalTriggerMethod
        
        %InternalSamplingInterval - Internal storage for sampling interval setting
        %   This is user-exposed through the SamplingInterval property.
        InternalSamplingInterval = 1
        
        %InternalMinEffectiveParticleRatio - Internal storage for minimum effective particle ratio
        %   This is user-exposed through the MinEffectiveParticleRatio property.
        InternalMinEffectiveParticleRatio = 0.5
    end
    
    properties (Access = {?matlabshared.tracking.internal.ResamplingPolicy, ?matlab.unittest.TestCase})
        %IntervalCounter - Counter for how often a correction was called
        %   The value of the property is incremented each time the isResamplingTriggered
        %   method is called.
        IntervalCounter = 0
    end
    
    %% Constructor and Copy Method
    methods
        function obj = ResamplingPolicy
            %ResamplingPolicy Constructor for object
            
            % Set internal value and make sure it is recognized as varsize
            % for code generation. This will also mark the
            % InternalTriggerMethod property as varsize.
            defaultTrigger = 'ratio';
            coder.varsize('defaultTrigger', [1 20], [0 1]);
            obj.InternalTriggerMethod = defaultTrigger;
            
            % Set default values
            obj.TriggerMethod = defaultTrigger;
            obj.SamplingInterval = 1;
            obj.MinEffectiveParticleRatio = 0.5;
            
            % Reset object state
            obj.reset;
        end
        
        function cObj = copy(obj)
            %copy Creates a copy of the object
            %   COBJ = copy(OBJ) creates a deep copy of the ResamplingPolicy
            %   object OBJ and returns it in COBJ. OBJ has to be a scalar
            %   handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            
            coder.internal.errorIf(~isscalar(obj), 'shared_tracking:particle:PolicyCopyNotScalar', ...
                'ResamplingPolicy');
            
            % Create a new object with the same properties
            % Use the object's runtime class to allow copying of derived
            % classes.
            fcnClassName = str2func(class(obj));
            cObj = fcnClassName();
            
            % Preserve deleted handle
            if coder.target('MATLAB')
                % isvalid and delete are not supported in code generation
                if ~isvalid(obj)
                    cObj.delete;
                    return;
                end
            end
            
            % Assign the internal data to the new object handle
            cObj.InternalTriggerMethod = obj.InternalTriggerMethod;
            cObj.InternalSamplingInterval = obj.InternalSamplingInterval;
            cObj.InternalMinEffectiveParticleRatio = obj.InternalMinEffectiveParticleRatio;
            cObj.IntervalCounter = obj.IntervalCounter;
        end
    end
    
    %% Property Getters and Setters
    methods
        function trigger = get.TriggerMethod(obj)
            %get.TriggerMethod Get the sampling interval
            trigger = obj.InternalTriggerMethod;
        end
        
        function set.TriggerMethod(obj, trigger)
            %set.TriggerMethod Setting the trigger method
            validMethod = validatestring(trigger, {'ratio', 'interval'}, 'ResamplingPolicy', 'TriggerMethod');
            
            % Reset the object if trigger method is changed
            if ~strcmp(obj.InternalTriggerMethod, validMethod)
                obj.InternalTriggerMethod = validMethod;
                obj.reset;
            end
        end
        
        function interval = get.SamplingInterval(obj)
            %get.SamplingInterval Get the sampling interval
            interval = obj.InternalSamplingInterval;
        end
        
        function set.SamplingInterval(obj, interval)
            %set.TriggerMethod Setting the trigger method
            
            validateattributes(interval, {'numeric'}, {'scalar', 'real'}, 'ResamplingPolicy', 'SamplingInterval');
            
            if ~isinf(interval)
                % Allow infinity as setting for the sampling interval
                % All other input values have to be integers
                validateattributes(interval, {'numeric'}, {'scalar', 'nonnan', 'real', 'nonnegative', 'integer', 'nonempty'}, 'ResamplingPolicy', 'SamplingInterval');
            end
            newInterval = double(interval);
            
            % Reset the object if sampling interval changes
            if newInterval ~= obj.InternalSamplingInterval
                obj.InternalSamplingInterval = newInterval;
                obj.reset;
            end
        end
        
        function ratio = get.MinEffectiveParticleRatio(obj)
            %get.MinEffectiveParticleRatio Get the minimum effective particle ratio
            ratio = obj.InternalMinEffectiveParticleRatio;
        end
        
        function set.MinEffectiveParticleRatio(obj, ratio)
            %set.MinEffectiveParticleRatio Setting the minimum effective particle ratio
            validateattributes(ratio, {'numeric'}, {'nonempty', 'scalar', 'real', 'nonnan', 'finite', '>=', 0, '<=', 1}, 'ResamplingPolicy', 'MinEffectiveParticleRatio');
            obj.InternalMinEffectiveParticleRatio = double(ratio);
        end
        
    end
    
    %% Hidden Interface
    methods (Hidden)
        function trigger = isResamplingTriggered(obj, weights)
            %isResamplingTriggered Determine if resampling should be triggered
            
            assert(isvector(weights));
            
            trigger = false;
            
            switch obj.TriggerMethod
                case 'interval'
                    % Trigger resampling if our interval counter is an
                    % integer multiple of the desired SamplingInterval
                    [trigger,obj.IntervalCounter] = matlabshared.tracking.internal.ResamplingPolicy.checkIntervalTrigger(obj.IntervalCounter, obj.SamplingInterval);
                case 'ratio'
                    % Trigger resampling if ratio of effective to total
                    % particles falls below threshold.
                    trigger = matlabshared.tracking.internal.ResamplingPolicy.checkRatioTrigger(weights,obj.MinEffectiveParticleRatio);
                    
                otherwise
                    assert(false);
            end
        end
    end
    
    %% Static Methods
    % These are utilized by this object and the PF block
    methods (Static, Hidden)
        function [isTriggered,counter] = checkIntervalTrigger(counter,interval)
            % checkIntervalTrigger Increase the counter, check if it has reached the interval
            %
            % Used for checking if resampling is triggered/required.
            
            % Increase the counter
            counter = counter + 1;
            % Check the trigger condition
            isTriggered = mod(counter, interval) == 0;
            % Avoid counting toward Inf unless SamplingInterval is Inf
            if isTriggered
                counter = cast(0,'like',counter);
            end
        end
        
        function isTriggered = checkRatioTrigger(weights, minRatio)
            % checkRatioTrigger Check if ratio of effective to total
            % particles is below the threshold minRatio
            %
            % Used for checking if resampling is triggered/required.
            squaredSum = sum(weights .^ 2);
            assert(squaredSum > 0);
            
            % The effective particle size, neff, is calculated based
            % on equation (51) in reference [1] and equation (90)
            % in reference [2]
            neff = 1 / squaredSum;
            neffRatio = neff / numel(weights);
            
            % Trigger resampling if ratio is less than user-specified
            % threshold
            isTriggered = neffRatio < minRatio;
        end
    end
    
    %% Internal Methods
    methods (Access = protected)
        function reset(obj)
            %reset Reset the state of the object
            
            % Reset interval counter to 0
            obj.IntervalCounter = 0;
        end
    end
    
end
