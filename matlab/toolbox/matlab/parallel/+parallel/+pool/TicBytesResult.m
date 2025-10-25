classdef TicBytesResult
%

% Copyright 2016-2024 The MathWorks, Inc.

    % Hide the internal properties of this object
    properties (SetAccess  = immutable, GetAccess = private)
        PoolID
        Values
    end

    methods (Static, Access = ?parallel.Pool)
        function obj = createForEmptyPool()
            obj = parallel.pool.TicBytesResult([]);
        end

        function obj = createForUnsupportedPool()
            obj = parallel.pool.TicBytesResult(NaN);
        end
    end
    
    % Only allow methods of this class to be called from methods of
    % parallel.Pool so that a user can't make them
    methods (Access = ?parallel.Pool)
        function obj = TicBytesResult(pool)
            % Construction needs to differentiate between an empty pool
            % input (which means there is no current pool) and a fully
            % connected pool.
            if ~isnumeric(pool) && ~isempty(pool) && pool.Connected
                obj.PoolID = pool.ID;
                obj.Values = iGetCurrentValuesFromPool(pool);
            else
                obj.PoolID = 0;
                obj.Values = containers.Map('KeyType', 'double', 'ValueType', 'any');
                if isnumeric(pool) && isscalar(pool) && isnan(pool)
                    % Get here from createForUnsupportedPool
                    obj.PoolID = NaN;
                end
            end
        end
        
        function r = minus(A, B)
            % Implementation of difference between 2 TicBytesResult objects
            % which returns a matrix with the bytes transferred between the
            % retrieval of the objects
            if ~isequaln(A.PoolID, B.PoolID)
                error(message('MATLAB:parallel:pool:TicBytesDifferentPool'));
            end
            r = iDiffValues(A.Values, B.Values);
        end
        
        function dispMinus(A, B)
            % Display variant of difference between 2 TicBytesResults
            % objects.
            r = A - B;
            iDisplayTocBytesAsTable(r, B.PoolID);
        end
    end
    
end

function o = iGetCurrentValuesFromPool(p)
% Internal helper function to interrogate a pool and extract how many bytes
% have been sent and received from workers.
o = p.hGetEngine().getCurrentBytesTransferredToInstances();
end

function diff = iDiffValues(endValue, startValue)
% Helper to subtract two maps which may have different keys. If the start
% value is missing an entry assume it has 0 value
endKeys = keys(endValue);
diff = zeros(numel(endKeys), 2);
for idx = 1:numel(endKeys)
    index = endKeys{idx};
    start = 0;
    if isKey(startValue, index)
        start = startValue(index);
    end
    diff(idx, :) = endValue(index) - start;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  iDisplayTocBytesAsTable(o, id)
nLabs = size(o, 1);
if nLabs > 0
    labsNames = cellstr(num2str((1:nLabs).'));
else
    labsNames = {};
end
rowNames = [labsNames ; {'Total'}];
% ID < 0 indicates an unsupported pool
if isnan(id)
    c = [NaN, NaN];
else
    c = [o ; sum(o, 1)];
end
t = table( c(:, 1), c(:, 2), ...
    'VariableNames', {'BytesSentToWorkers', 'BytesReceivedFromWorkers'}, ...
    'RowNames', rowNames );
disp(t);
end
