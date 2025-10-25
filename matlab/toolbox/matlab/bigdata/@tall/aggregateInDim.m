function [out,dim] = aggregateInDim(fcn, obj, args, aggregateFlags, reduceFlags)
%AGGREGATEINDIM Aggregation and reduction along a dimension
%
% Result OUT is a new tall array. The caller must update the Adaptor.
% Result DIMUSED indicates the reduction dimension, empty if unknown.

%   Copyright 2018 The MathWorks, Inc.

% if no dimension specified, try to deduce it.
if isempty(args)
    dim = matlab.bigdata.internal.util.deduceReductionDimension(obj.Adaptor);
    if ~isempty(dim)
        args = {dim};
    end
else
    dim = args{1};
end

if isempty(args)
    % Reduction in default dimension.
    aggregateFun = @(x, dim) fcn(x, dim, aggregateFlags{:});
    reduceFun = @(x, dim) fcn(x, dim, reduceFlags{:});
    out = tall(reduceInDefaultDim({aggregateFun, reduceFun}, obj));
else
    assert(matlab.bigdata.internal.util.isValidReductionDimension(dim), ...
        'Dimension must have been validated before.');
    % DIM is allowed to be a column or row vector. We want a row vector.
    if iscolumn(dim)
        dim = dim';
    end
    % Reduction in specified dimension(s)
    aggregateFun = iFunctor(fcn, dim, aggregateFlags{:});
    reduceFun = iFunctor(fcn, dim, reduceFlags{:});
    
    if isReducingTallDimension(dim)
        out = aggregatefun(aggregateFun, reduceFun, obj);
    else
        out = slicefun(aggregateFun, obj);
    end
end
end

function functor = iFunctor(fcn, dim, varargin)
functor = @(data) fcn(data, dim, varargin{:});
end
