function varargout = size(obj, varargin)
%SIZE Size of a tall array
%   D = SIZE(X)
%   [M,N] = SIZE(X)
%   M = SIZE(X,DIM)
%   M = SIZE(X,DIM1,DIM2,...,DIMN)
%   [M1,M2,...,MN] = SIZE(X)
%   [M1,M2,...,MN] = SIZE(X,DIM)
%   [M1,M2,...,MN] = SIZE(X,DIM1,DIM2,...,DIMN)
%
%   See also TALL/NUMEL, TALL/NDIMS.

%   Copyright 2015-2023 The MathWorks, Inc.

numOutputs = max(1, nargout);
varargout = cell(1, numOutputs);
if nargin>1
    % Dimension argument must not be tall, but we can call built-in SIZE 
    % to do the rest of the error checking.
    tall.checkNotTall(mfilename,1,varargin{:});
    tall.validateSyntax(@size, [{obj}, varargin], ...
        'DefaultType', 'double', 'NumOutputs', numOutputs);

    % If we got multiple dimension inputs they must be scalars and can be
    % combined into a single dimVec. If only one, it *is* the dimVec.
    if nargin>2
        dim = cat(2, varargin{:});
    else
        dim = varargin{1};
    end
end

% We might be able to return ready-gathered data for some cases.
executor = getExecutor(obj);
if nargin==2 && nargout<=1 && isempty(dim)
    % For empty make sure we always get a row
    varargout{1} = tall.createGathered(zeros(1,0), executor);
    return
end
adaptor = obj.Adaptor;
if ~isnan(adaptor.NDims)
    szVec = adaptor.Size;
    if nargin == 1 && all(~isnan(szVec))
        % Either [a,b,...] = size(x), or sz = size(x)
        [varargout{1:max(1, nargout)}] = iSplitSize(szVec);
        % Convert to talls
        varargout = cellfun( @(data)tall.createGathered(data, executor), varargout, 'UniformOutput', false );
        return
    end
    if nargin > 1
        if any(dim > numel(szVec))
            % Pad with ones
            szVec = [szVec, ones(1, max(dim)-numel(szVec))];
        end
        outDims = szVec(dim);
        % If all dimensions are known we can return immediately.
        if ~any(isnan(outDims))
            if isscalar(varargout)
                varargout{1} = tall.createGathered(outDims, executor);
            else
                for ii=1:numOutputs
                    varargout{ii} = tall.createGathered(outDims(ii), executor);
                end
            end
            return
        end
    end
end

% We couldn't return an immediate result, so setup the deferred calculation
if nargin == 1
    [varargout{1:max(1, nargout)}] = aggregatefun(@size, @iCombineSize, obj);
elseif numOutputs == 1
    varargout{1} = aggregatefun(@(x) iDimSize(x, dim), @(x) iDimSizeCombine(x, dim), obj);
else
    % Multiple scalar outputs. Get the vector then break into scalars.
    outVec = aggregatefun(@(x) iDimSize(x, dim), @(x) iDimSizeCombine(x, dim), obj);  
    [varargout{1:max(1, nargout)}] = clientfun(@iSplitSize, outVec);
end

% Set up output adaptors because we know the size of the results.
if isscalar(varargout) && nargin == 1
    % Row-vector output. Note we use 'adaptor.NDims' which might be NaN,
    % or it might contain the actual number of dimensions
    varargout{1}.Adaptor = setKnownSize(matlab.bigdata.internal.adaptors.getAdaptorForType('double'), ...
                                        [1 adaptor.NDims]);
elseif isscalar(varargout) && nargin == 2
    % Row-vector output based on dimension vector input
    varargout{1}.Adaptor = setKnownSize(matlab.bigdata.internal.adaptors.getAdaptorForType('double'), ...
                                        [1 numel(dim)]);
else
    % One or more scalar outputs.
    for idx = 1:numel(varargout)
        varargout{idx}.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
    end
end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper for combining all sizes across partitions
function varargout = iCombineSize(varargin)
varargout = cell(1, nargout);
% Differentiate between vector size and multiple size outputs
if nargin==1
    in = varargin{1};
    assert(~isempty(in), "input to CombineSize should never be empty (@size always returns non-empty)");
    out = in(1, :);
    out(1) = sum(in(:, 1));
    varargout{1} = out;
else
    % For multiple out, sum the first and keep first element of the rest
    varargout{1} = sum(varargin{1}, 1);
    for idx = 2:nargout
        in = varargin{idx};
        varargout{idx} = in(1 : min(1, end));
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper for splitting a size vector into multiple outputs if nargout>1
function varargout = iSplitSize(szVec)

% Simply return the vector if nargout==1 (i.e. szvec = size(x))
if nargout==1
    varargout = {szVec};
    return
end

% If there are fewer outputs than dimensions, combine all trailing
% dimension. If more, pad with ones.
numSz = numel(szVec);
if nargout<numSz
    szVec(nargout) = prod(szVec(nargout:end));
elseif nargout>numSz
    szVec = [szVec, ones(1, nargout-numel(szVec))];
end
varargout = num2cell(szVec);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper to measure the input size in one or more specified dimensions
function out = iDimSize(in, dim)
out = size(in, dim);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper to combine partial size results across partitions
function out = iDimSizeCombine(in, dim)

% We might be combining multiple dimensions. These should match between
% blocks (i.e. we can just keep the first) except for the tall dimension,
% which must be summed.
out = in(1,:);
if size(in,1)>1 && any(dim==1)
    out(1, dim==1) = sum(in(:,dim==1), 1);
end

end
