function samples = sampleUniformImpl(randData, mu, deviationBound)
%This function is for internal use only. It may be removed in the future.

%sampleUniformImpl Remaps a standard-uniformly sampled N-by-M matrix to a new uniform space
%
%   This function takes in uniformly sampled data between [0 1] and 
%   transforms it to a set of uniform state-spaces, where each pair of mu/deviationBound
%   elements defines the sample-space for its corresponding state.
%
%   If the output is an N-element state-vector, then randData is expected
%   to be an N-by-M matrix. mu and deviationBound must both be 1-by-M row vectors.
%
%   If the output is an N-element state-vector, then the dimensions of
%   randData, mu, and deviationBound must be flipped.

    %   Copyright 2019 The MathWorks, Inc.
    
    %#codegen

    % Avoid a + (b-a)*rand in case b-a > realmax
    randSamples = 2 * randData - 1; % Row

    % Scale
    scaledSamples = bsxfun(@times, randSamples, deviationBound);

    % Offset
    samples = bsxfun(@plus, scaledSamples, mu);
end