function [out,dim] = reduceInDim(fcn, obj, varargin)
%REDUCEINDIM Reduction along a dimension
%
% Result OUT is a new tall array. The caller must update the Adaptor.
% Result DIMUSED indicates the reduction dimension, empty if unknown.

%   Copyright 2015-2018 The MathWorks, Inc.

FCN_NAME = upper(func2str(fcn));
tall.checkNotTall(FCN_NAME, 1, varargin{:});
% Need to handle flags for SUM and PROD.
[args, flags] = splitArgsAndFlags(varargin{:});

% Only allowed arg is the dimension, so error if got more than that.
assert(numel(args) <= 1, 'Up to one dimension argument is accepted. It must have been validated before.');

% Interpret flags
adaptor = obj.Adaptor;
[nanFlagCell, precisionFlagCell] = adaptor.interpretReductionFlags(FCN_NAME, flags);
flags = [nanFlagCell, precisionFlagCell];

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
    out = tall(reduceInDefaultDim(fcn, obj, flags{:}));
    
else
    if ~matlab.bigdata.internal.util.isValidReductionDimension(dim)
        error(message('MATLAB:getdimarg:invalidDim'));
    end
    % DIM is allowed to be a column or row vector. We want a row vector.
    if iscolumn(dim)
        dim = dim';
    end
    % Reduction in specified dimension
    functor = iFunctor(fcn, dim, flags{:});
    if isReducingTallDimension(dim)
        % Includes tall dimension, so need communicating reduction
        out = reducefun(functor, obj);
    else
        % Non-tall dims can be reduced for each slice independently
        out = slicefun(functor, obj);
    end
end
end

function functor = iFunctor(fcn, dim, varargin)
functor = @(data) fcn(data, dim, varargin{:});
end
