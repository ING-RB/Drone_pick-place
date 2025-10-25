function samples = sampleGaussianImpl(randData, mu, stdDev)
%This function is for internal use only. It may be removed in the future.

%sampleGaussianImpl Remaps a standard-normally distributed N-by-M matrix to a Gaussian Space formed by mu and stdDev
%
%   This function takes in an N-by-M matrix of data, randData, sampled from
%   a standard-normal distribution and maps each column to a corresponding
%   gaussian distributions, defined by corresponding elements in mu and stdDev,
%   which are both 1-by-M vectors.

    %   Copyright 2019 The MathWorks, Inc.
    
    %#codegen

    zeroMeanSamples = randData * stdDev;

    samples = bsxfun(@plus, zeroMeanSamples, mu);
end