function A = adjacency(G, w_in)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if nargin <= 1
    A = adjacency(G.Underlying);
else
    coder.internal.assert(~G.ismultigraph(), ...
        'MATLAB:graphfun:adjacency:WeightedMultigraph');
    if matlab.internal.coder.graphBase.isvalidoption(w_in)
        coder.internal.assert(matlab.internal.coder.graphBase.partialMatch(w_in, "weighted"), ...
            'MATLAB:graphfun:adjacency:InvalidWeights');
        [w, hasEdgeWeights] = getEdgeWeights(G);
        if ~hasEdgeWeights
            w = ones(numedges(G), 1);
        end
    else
        w = w_in;
    end

    coder.internal.assert((isnumeric(w) || islogical(w)) && isvector(w), ...
        'MATLAB:graphfun:adjacency:InvalidWeights')
    coder.internal.assert(length(w) == numedges(G) && (isa(w,'double') ...
        || isa(w,'logical')), 'MATLAB:graphfun:adjacency:InvalidWeightVector');

    if issparse(w)
        wFull = full(w);
    else
        wFull = w;
    end

    A = adjacency(G.Underlying, wFull);
end
