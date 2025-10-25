classdef MultinomialResampler < matlabshared.tracking.internal.Resampler
    %MultinomialResampler Multinomial resampling algorithm
    %   Multinomial resampling is also called simplified random sampling.
    %   The algorithm generates N random numbers independently from the
    %   uniform distribution in the open interval (0, 1) and uses them to 
    %   select particles proportional to their weight.
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
            
            % Generate N random numbers and sort them
            randSamples = sort(rand(1,numNewParticles,'like',weights));
            
            % Find indices in weights corresponding to random numbers in randSamples
            sampleIndices = obj.findSortedSampleIndices(weights, randSamples);
        end
        
    end
    
end

