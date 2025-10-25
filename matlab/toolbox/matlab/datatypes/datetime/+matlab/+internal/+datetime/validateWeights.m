function weights = validateWeights(weights,data,omitnan,isDimSet,allFlag,dim)
%VALIDATEWEIGHTS Validate weights for mean or median.
%   X = VALIDATEWEIGHTS(WEIGHTS, DATA, OMMITNAN, ISDIMSET, ALLFLAG, DIM) 
%   errors if WEIGHTS i not compatible in size with DATA.

%   Copyright 2024 The MathWorks, Inc.

% Adapted from matlab.internal.math.parseWeights
if ~isreal(weights) || ~isfloat(weights) || ...
        (omitnan && any(weights < 0,'all')) || (~omitnan && ~all(weights >= 0,'all'))
    error(message('MATLAB:weights:InvalidWeight'));
end
if isDimSet && (isempty(dim) || allFlag || ~isscalar(dim))
    error(message('MATLAB:weights:WeightWithVecdim'));
end
if isequal(size(data),size(weights))
    reshapeWeights = false;
elseif isvector(weights)
    if (numel(weights) ~= size(data,dim))
        error(message('MATLAB:weights:InvalidSizeWeight'));
    end
    reshapeWeights = true;
else
    if ~isequal(size(data),size(weights))
        error(message('MATLAB:weights:InvalidSizeWeight'));
    end
end
if isvector(weights) && reshapeWeights
    % Reshape w to be applied in the direction dim
    sz = size(data);
    sz(end+1:dim) = 1;
    wresize = ones(size(sz));
    wresize(dim) = sz(dim);
    weights = reshape(weights, wresize);
    % Repeat w, such that the new w has the same size as data
    wtile = sz;
    wtile(dim) = 1;
    weights = repmat(weights, wtile);
end
