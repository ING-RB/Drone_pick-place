%ConstantEntry Handle class that manages which pools have knowledge of a
%particular Constant.

% Copyright 2022-2024 The MathWorks, Inc.

classdef ConstantEntry < handle

    properties (SetAccess = immutable)
        % Cache the ID, so we can use it within this class to perform
        % remote operations.
        ID
    end

    properties (Access = private)
        ConstantData
    end

    properties (Transient, Access = private)
        PoolMap = dictionary(string.empty(), parallel.Pool.empty());
    end

    methods
        function obj = ConstantEntry(id, arg, cleanupFcn)
            obj.ID = id;

            if isa(arg, 'Composite')
                % Composite constructor
                % Get the pool backing this Composite
                try
                    resourceSet = hGetResourceSet(arg);
                    if ~isempty(resourceSet)
                        pool = resourceSet.getPoolIfAny();
                    else
                        pool = parallel.Pool.empty();
                    end
                catch E
                    error(message('MATLAB:parallel:constant:ConstantInvalidComposite'));
                end

                if iIsSerialPool(pool)
                    data = parallel.internal.constant.ValueBasedData(arg);
                else
                    % Ensure Composite is defined on all workers
                    if numel(arg) ~= pool.NumWorkers || ...
                            ~all(exist(arg)) %#ok<EXIST> wrong 'exist'
                        error(message('MATLAB:parallel:constant:ConstantInvalidComposite'));
                    end

                    assistant = pool.hGetEngine().getConstantAssistant();
                    assistant.buildFromComposite(id, arg);

                    % To keep a valid ID, a Constant must have a local
                    % entry. We insert an error message in case a user
                    % tries to retrieve the value in the client.
                    cleanupFcn = function_handle.empty();
                    data = parallel.internal.constant.FunctionBasedData(@iThrowCompositeOnClientError, cleanupFcn);

                    % Add the pool to the list of known pools.
                    obj.addPoolToMap(pool);
                end
            elseif isa(arg, 'function_handle')
                data = parallel.internal.constant.FunctionBasedData(arg, cleanupFcn);
            else
                % Value.
                data = parallel.internal.constant.ValueBasedData(arg);
            end
            obj.ConstantData = data;
        end

        function v = getValue(obj)
            obj.initialize();
            v = obj.ConstantData.getValue();
        end

        function initialize(obj)
            obj.ConstantData = obj.ConstantData.initialize();
        end

        function broadcast(obj, poolId)
            % Return early if we've already seen this poolId.
            if isKey(obj.PoolMap, poolId)
                 return
            end

            % At this point, get the pool from its associated Id.
            pool = parallel.internal.pool.PoolManager.getInstance().getPoolFromUUID(poolId);
            if iIsSerialPool(pool)
                return
            end

            % Add the pool to the list of known pools for this ID. Do this
            % before the pool broadcast to prevent the possibility of an
            % infinite serialization recursion occurring here.
            obj.addPoolToMap(pool);

            parallel.internal.constant.doBroadcast(pool, obj.ID, obj);
        end

        function args = getConstructorArgs(obj)
            args = obj.ConstantData.getConstructorArgs();
        end

        function err = cleanup(obj)
            try
                obj.ConstantData.cleanup();
                err = MException.empty();
            catch err
                % Return any errors
            end

            pools = values(obj.PoolMap);

            for ii = 1:numel(pools)
                obj.cleanupOnPool(pools(ii));
            end
        end
    end

    methods (Access = private)

        function addPoolToMap(obj, pool)
            poolId = pool.hGetUUID();
            obj.PoolMap(poolId) = pool;
        end

        function cleanupOnPool(obj, pool)
            % This method attempts to be no-throw, and instead
            % asynchronously reports errors as warnings.
            if ~isvalid(pool)
                return
            end

            % Remove pool and clear remote data.
            poolID = pool.hGetUUID();
            obj.PoolMap(poolID) = [];

            if ~hGetIsUsable(pool)
                return
            end

            try
                assistant = pool.hGetEngine().getConstantAssistant();
                assistant.clearConstant(pool, obj.ID);
            catch
                % Pool may have become invalid (e.g. lost worker), don't report this.
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function value = iThrowCompositeOnClientError()
% Function that gets evaluated when we try to get the value of a Composite on the
% client. Rather than return a value, it always throws an error.
value = []; %#ok<NASGU>
error(message('MATLAB:parallel:constant:ConstantCompositeValueOnClient'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsSerialPool(pool)
tf = isempty(pool) || isa(pool,"matlab.internal.serialPool");
end
