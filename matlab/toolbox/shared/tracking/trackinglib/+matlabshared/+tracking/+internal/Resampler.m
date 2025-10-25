classdef (Abstract) Resampler < handle
    %Resampler Base class for all particle filter resampling methods
    %   All derived classes need to implement a "resample" method.
    
    %   Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen    
    
    methods (Abstract)
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
        sampleIndices = resample(~, weights, numSamples)
    end
    
    methods (Access = protected)
        function sampleIndices = findSortedSampleIndices(~, weights, randSamples)
            %findSortedSampleIndices Find indices of samples in cumulative sum
            %   The input CUMSUMWEIGHTS is the cumulative sum of all weights (last
            %   element is 1.0, vector of size 1-by-M). The input RANDSAMPLES is the
            %   1-by-N vector of random numbers in the interval between 0
            %   and 1. RANDSAMPLES has to be in sorted order.
            %
            %   SAMPLEINDICES returns the indices in CUMSUMWEIGHTS that define the
            %   interval in which the random numbers RANDSAMPLES can be found.
            %   SAMPLEINDICES is a vector of size 1-by-N.
            
            m = length(weights);
            n = length(randSamples);
            
            % Compute the cumulative sum of all weights.
            % Since the input weights are normalized, the last element in
            % cumSumWeights will be 1.0.
            cumSumWeights = cumsum(weights);
            assert( abs(cumSumWeights(end) - 1.0) < sqrt(eps(class(weights))) );
            
            % Compute indices of resample choices
            % By default, use index of 1 (fallback in case that weights are
            % not normalized).
            sampleIndices = ones(1,n,'like',weights);
            
            % Find elements in cumulative sum that are greater or equal than the
            % random values. Store and return the found indices.
            
            % Take advantage of the fact that randSamples is sorted, so we only have
            % to iterate through cumSumWeights once.
            i = 1;
            j = 1;
            while i <= n && j <= m 
                while cumSumWeights(j) < randSamples(i) && j < m
                    % Find element in cumulative sum that is greater or
                    % equal to random number
                    j = j + 1;
                end
                
                % Random number falls within the interval defined by the
                % weight at index j. Save the index.
                sampleIndices(i) = j;
                
                % Look at next random number
                i = i + 1;
            end
        end
    end
end

