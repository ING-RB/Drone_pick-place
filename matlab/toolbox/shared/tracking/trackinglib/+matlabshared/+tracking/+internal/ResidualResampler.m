classdef ResidualResampler < matlabshared.tracking.internal.Resampler
    %ResidualResampler Residual resampling algorithm
    %   Residual resampling  consists of two stages. The first is
    %   a deterministic replication of each particle that have weights larger 
    %   than 1/N. The second stage consists of random sampling using the
    %   remainder of the weights (labelled as residuals).
    %
    %   Reference:
    %   T. Li, M. Bolic, P.M. Djuric, "Resampling Methods for Particle
    %   Filtering: Classification, implementation, and strategies," IEEE
    %   Signal Processing Magazine, vol. 32, no. 3, pp. 70-86, May 2015
    
    %   Copyright 2015-2020 The MathWorks, Inc.
    
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
                        
            numWeights = length(weights);
            
            sampleIndices = ones(1, numNewParticles, 'like', weights);

            % Find particles with weight >= 1/numNewParticles
            % The multiplication by numNewParticles (and subsequent) floor determines how
            % many times the particle should be replicated.
            if weights(1) == weights(end) && all(weights == weights(1))
            % Resolves floating-pt precision error when weights are uniformly 
            % distributed(g2280695)
                numRep = floor(numNewParticles/numWeights);
                replicationCount = numRep*ones(size(weights));                
            else
                replicationCount = floor(numNewParticles * weights);
            end
            
            % The total number of replicated particles (will be drawn
            % deterministically)
            numReplications = sum(replicationCount);
            
            % Stage 1: Deterministic replication of particles
            i = 1;
            for j = 1:numWeights
                for k = 1:replicationCount(j)
                    sampleIndices(i) = j;
                    i = i + 1;
                end
            end
            
            % Stage 2: Multinomial resampling of remaining particles

            % The number of particles which will be drawn randomly
            numRandom = numNewParticles - numReplications;
            if numRandom == 0
                % Return if no random particles have to be drawn
                return;
            end
            
            % The modified weights
            % 1. Calculate the fractional weights (weights - replicationCount / numNewParticles)
            % 2. Multiply by numNewParticles/numRandom to ensure that weights sum up to 1
            modWeights =(numNewParticles * weights - replicationCount)/numRandom;

            % Draw random samples and do multinomial resampling
            randSamples = sort(rand(1,numRandom,'like',weights));
            sampleIndices(i:end) = obj.findSortedSampleIndices(modWeights, randSamples);
        end        
    end
    
end

