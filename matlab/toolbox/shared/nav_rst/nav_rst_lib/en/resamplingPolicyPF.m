classdef resamplingPolicyPF< handle
%resamplingPolicyPF Create resampling policy for particle filter
%   After a sensor measurement is incorporated in the particle
%   filter during the correction stage, a resampling of all particles
%   might occur.
%
%   The settings in this object determine if and when resampling should
%   occur.
%
%   POLICY = resamplingPolicyPF creates a
%   resamplingPolicyPF object POLICY. Its properties can be modified to control
%   when resampling should be triggered.
%
%
%   resamplingPolicyPF properties:
%       TriggerMethod             - Method used for determining if resampling should be triggered
%       SamplingInterval          - Fixed interval between resampling
%       MinEffectiveParticleRatio - Minimum desired ratio of effective to total particles
%
%
%   Example:
%
%      % Create policy object
%      pol = resamplingPolicyPF
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

    methods
        function out=resamplingPolicyPF
            %resamplingPolicyPF Constructor for object
        end

        function out=copy(~) %#ok<STOUT>
            %copy Creates a copy of the object
            %   COBJ = copy(OBJ) creates a deep copy of the resamplingPolicyPF
            %   object OBJ and returns it in COBJ. OBJ has to be a scalar
            %   handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
        end

        function out=reset(~) %#ok<STOUT>
            %reset Reset the state of the object
        end

    end
    properties
        %InternalMinEffectiveParticleRatio - Internal storage for minimum effective particle ratio
        %   This is user-exposed through the MinEffectiveParticleRatio property.
        InternalMinEffectiveParticleRatio;

        %InternalSamplingInterval - Internal storage for sampling interval setting
        %   This is user-exposed through the SamplingInterval property.
        InternalSamplingInterval;

        %InternalTriggerMethod - Internal storage for trigger method
        %   This is user-exposed through the TriggerMethod property.
        InternalTriggerMethod;

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
        MinEffectiveParticleRatio;

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
        SamplingInterval;

        %TriggerMethod - Method used for determining if resampling should be triggered
        %   Possible choices are 'ratio' and 'interval'. In the 'interval'
        %   method, the resampling is triggered in regular intervals, whereas
        %   the 'ratio' method triggers resampling based on the ratio of
        %   effective to total particles.
        %
        %   Default: 'ratio'
        TriggerMethod;

    end
end
