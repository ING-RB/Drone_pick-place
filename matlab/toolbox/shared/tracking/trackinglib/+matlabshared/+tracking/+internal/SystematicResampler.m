classdef SystematicResampler < matlabshared.tracking.internal.Resampler
    %SystematicResampler Systematic resampling algorithm
    %   Systematic resampling is similar to stratified resampling as it also
    %   makes use of strata. One distinction is that it only draws one random number
    %   from the open interval (0, 1/N) and the remaining sample points are
    %   calculated deterministically at a fixed 1/N step size.
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

            % Draw a single random number in open interval (0, 1/numNewParticles) and space
            % out all other samples, deterministically at 1/numNewParticles.
            % randSamples is in sorted order
            randSamples = linspace(cast(0,'like',weights), 1-1/numNewParticles, numNewParticles) + ...
                rand(1,1,'like',weights)/numNewParticles;
            
            % Find indices in weights corresponding to random numbers in randSamples
            sampleIndices = obj.findSortedSampleIndices(weights, randSamples);
        end
    end
end

