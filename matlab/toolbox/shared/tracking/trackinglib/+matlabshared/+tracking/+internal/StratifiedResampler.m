classdef StratifiedResampler < matlabshared.tracking.internal.Resampler
    %StratifiedResampler Stratified resampling algorithm
    %   Stratified resampling divides the whole population of particles into
    %   subsets called strata. It pre-partitions the [0, 1) interval
    %   into N disjoint sub-intervals of size 1/N. The random
    %   numbers are drawn independently in each of these sub-intervals and
    %   the sample indices chosen in the strata.
    %
    %   Reference:
    %   T. Li, M. Bolic, P.M. Djuric, "Resampling Methods for Particle
    %   Filtering: Classification, implementation, and strategies," IEEE
    %   Signal Processing Magazine, vol. 32, no. 3, pp. 70-86, May 2015
    
    %   Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen    
    
    methods
        function sampleIndices = resample(obj, weights, numNewParticles)
            %resample Resample set of particles based on their weights
            %   SAMPLEINDICES = RESAMPLE(OBJ, WEIGHTS, NUMSAMPLES) resamples
            %   based on the input WEIGHTS. SAMPLEINDICES is the 1-by-NUMSAMPLES
            %   vector of resampled indices into WEIGHTS. NUMSAMPLES can be any
            %   positive integer, with a common choice of NUMSAMPLES ==
            %   length(WEIGHTS) for a particle filter with a fixed number of
            %   particles.
            %
            %   Note that the input WEIGHTS are expected to be normalized (sum up
            %   to 1).
            
            narginchk(3,3);
            
            % Subdivide interval into segments with width 1/numNewParticles. Pick a
            % random number within this interval.
            % randSamples is in sorted order
            randSamples = linspace(cast(0,'like',weights), 1-1/numNewParticles, numNewParticles) + ...
                rand(1,numNewParticles,'like',weights)/numNewParticles;
            
            % Find indices in weights corresponding to random numbers in randSamples
            sampleIndices = obj.findSortedSampleIndices(weights, randSamples);
        end
    end
end

