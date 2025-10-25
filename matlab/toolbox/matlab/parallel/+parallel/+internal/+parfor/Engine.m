%Engine - Abstract base class for PARFOR engines.

% Copyright 2018-2024 The MathWorks, Inc.
classdef (Abstract) Engine < handle

    properties (SetAccess = immutable)
        DivisionFcn
    end
    
    methods (Abstract)
        [init, remainder] = getDispatchSizes(obj)
        OK = addInterval(obj, tag, intervalData)
        allIntervalsAdded(obj)
        [tags, results] = getCompleteIntervals(obj, numIntervals)
        complete(obj, errorDetected)
        W = getNumWorkers(obj)
    end
    
    methods (Access = private)
        function NN = callUserPartitionMethod(~, base, limit, partitionMethod, W)
            rangeSize = limit-base;
            try
                userResult = feval(partitionMethod, rangeSize, W);
            catch E
                throw(addCause(MException(message(...
                    'MATLAB:parallel:parfor:UserPartitionMethodErrored')), E));
            end
            if ~isnumeric(userResult) || ~isvector(userResult)
                error(message('MATLAB:parallel:parfor:UserPartitionMethodNotNumericVector'));
            end
            userResult = reshape(cast(userResult, 'like', 1.0), 1, []);

            if sum(userResult) ~= rangeSize || ...
                    ~all(userResult == round(userResult)) || ...
                    ~all(userResult > 0)
                error(message('MATLAB:parallel:parfor:UserPartitionMethodInvalidResult'));
            end
            NN = base + cumsum(userResult);
        end
    end

    methods (Static)
        function oldVal = numIntervalsFactor(newVal)
        % numIntervalsFactor allows control over the total number of intervals that
        % will get created in "auto" mode. The relationship is not linear,
        % depends on the number of workers and number of iterations, and is
        % determined by the implementation of divide_biharmonic. Here are
        % some sample numbers of intervals per worker for different values
        % of the factor, for a reference parfor loop with 8 workers and
        % 1000 iterations:
        % factor : approx intervals / worker
        %    0.5 : 4
        %    1   : 6
        %    2   : 6
        %    3   : 7
        %    4   : 8
        %    5   : 9
        %    6   : 10
        %
        % Note that when tuning PARFOR performance, there is an interaction
        % between the number of intervals and the maxBacklog. If the number
        % of intervals is relatively small, and backlog is high, then
        % towards the end of execution, poor load-balancing might be seen.
        % Contrariwise, if the allowed backlog is low and the number of
        % intervals is high, then the client must deal with a higher number
        % of messages, without necessarily being able to overlap this with
        % the worker execution.
        %
        % The default parameters chosen here attempt to balance the backlog
        % against the number of intervals produced across a range of parfor
        % loops.
            
            persistent FACTOR
            if isempty(FACTOR)
                FACTOR = 2; 
            end
            oldVal = FACTOR;
            if nargin > 0
                FACTOR = newVal;
            end
        end
    end
    
    methods
        function obj = Engine(partitionMethod, fixedSize)
            if isa(partitionMethod, 'function_handle')
                obj.DivisionFcn = @(srcObj, base, limit, W) srcObj.callUserPartitionMethod(base, limit, partitionMethod, W);
            elseif strcmp(partitionMethod, "auto")
                obj.DivisionFcn = @divide_biharmonic;
            else
                obj.DivisionFcn = @(~, base, limit, W) divide_fixed(base, limit, fixedSize);
            end
        end
        
        function NN = divideRangeIntoIntervals(obj, base, limit, W)
            k = limit - base;
            NN = obj.DivisionFcn(obj, base, limit, min(k, W));
            obj.rangeDivided(numel(NN));
        end
    end
    methods (Access = protected)
        function rangeDivided(obj, k) %#ok<INUSD>
        % Called when divideRangeIntoIntervals has been executed
        % and it is known how many intervals there will be.
        % Subclasses might wish to overload this - for example, they
        % could use this information to pre-allocate an array that is
        % needed to store something per interval.
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Divide the range into fixed-size sub-intervals
function output = divide_fixed(base, limit, fixedSize)
    output = (base+fixedSize):fixedSize:limit;
    if isempty(output) || output(end) < limit
        output(end+1) = limit;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Divide the range into a "biharmonic" series. This starts with a one small
% interval for each worker. The initial intervals are small to allow the
% client to send them more quickly to get the workers started more quickly
% at the start of the loop. The middle intervals saturate at the maxChunk
% size, and then decay to a small value. The end intervals are small to
% allow for better worker utilisation at the end of loop execution. We
% allways create nWorker copies of each chunk size. That way, if all the
% iterations take the same amount of time, each worker will be assigned the
% same set of chunk sizes, and take the same amount of time.
function output = divide_biharmonic(~, base, limit, nWorkers)
% double for consistent rounding behaviour 
    nIterations = double(limit - base);
    nWorkers = double(nWorkers);

    scaleFactor = parallel.internal.parfor.Engine.numIntervalsFactor();
    minChunk = ceil(max(1, ceil(nIterations/(scaleFactor * 10 * nWorkers))));
    maxChunk = floor(max(1, ceil(nIterations/(scaleFactor * nWorkers))));
    
    iterationsPerWorker = floor(nIterations/nWorkers);       
    
    % We first compute the chunk sizes for a single worker, before
    % replicating each one nWorker times below.
    chunkSizes = zeros('like', base);
    
    curr = 0;
    idx = 0;
    
    % First one small chunk
    firstChunk = min(iterationsPerWorker, minChunk);
    if firstChunk > 0
        idx = idx + 1;
        curr = curr + firstChunk;
        chunkSizes(idx) = firstChunk;
    end
    
    % Then harmonically decreasing chunk sizes
    while curr < iterationsPerWorker
        chunk = ceil((iterationsPerWorker - curr) / 2);
        chunk = iClamp(chunk, minChunk, maxChunk);
        curr = curr + chunk;
        idx = 1 + idx;
        chunkSizes(idx) = chunk;
    end
    
    chunkSizes(end) = chunkSizes(end) - (curr -iterationsPerWorker);
    
    % Rather than the chunk sizes, we output the limits between the
    % chunks. We use the chunk sizes we've computed for a single
    % worker to do this, we'll first have nWorkers copies of the first
    % chunk size, then nWorkers of the second chunk size and so on.
    allChunkSizes = reshape(repmat(chunkSizes, nWorkers, 1), 1, []);
    
    % Add any remainder as extra chunks
    remainder = mod(nIterations,nWorkers);
    allChunkSizes = [allChunkSizes , ones(1, remainder)];
    
    output = base + cumsum(allChunkSizes);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = iClamp(inVal, minBound, maxBound)
    val = min(max(inVal, minBound), maxBound);
end
