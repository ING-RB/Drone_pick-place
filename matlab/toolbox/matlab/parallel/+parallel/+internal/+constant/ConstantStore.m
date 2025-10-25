%ConstantStore Class that stores instances of ConstantEntry that back
%parallel.pool.Constant.

% Copyright 2023-2024 The MathWorks, Inc.

classdef ConstantStore < handle

    properties (Access = private)
        %DataMap Maps an ID representing a Constant to the underlying
        %ConstantEntry.
        %
        DataMap = dictionary(string.empty(), parallel.internal.constant.ConstantEntry.empty())
    end

    methods (Access = private)
        function obj = ConstantStore()   
        end
    end

    methods
        function tf = isKey(obj, id)
            tf = isKey(obj.DataMap, id);
        end

        function storeEntry(obj, id, entry)
            % Worker-side method to store a ConstantEntry with a given ID.
            % Performs any initialization of entry if required.
            arguments
                obj     (1,1) parallel.internal.constant.ConstantStore
                id      (1,1) string
                entry   (1,1) parallel.internal.constant.ConstantEntry
            end
            if obj.isKey(id)
                % This worker already has this entry. Since entries are
                % immutable, ignore.
                return
            end
            % Initialize the entry now.
            entry.initialize();
            obj.DataMap(id) = entry;
        end

        function entry = getEntry(obj, id)
            % Return a ConstantEntry from the store with a given ID.
            entry = obj.DataMap(id);
        end

        function entry = removeEntry(obj, id)
            % Remove and return a ConstantEntry from the store with a given
            % ID.
            entry = obj.getEntry(id);
            obj.DataMap(id) = [];
        end
    end

    methods(Static)
        function obj = getInstance(action)
            % Get the singleton ConstantStore for this MATLAB context.
            arguments
                action {mustBeTextScalar} = "get"
            end

            mlock;
            persistent STORE

            if strcmp(action, "reset")
                STORE = dictionary(string.empty(), parallel.internal.constant.ConstantStore.empty());
                return
            end

            % Thread-based pools in the same process are allowed to share workers. In
            % order to avoid leaking state from one pool to another, ConstantStore for
            % thread-workers is one-per-logical-pool. Note, this id is "" for the
            % client and process-based workers.
            poolSessionId = matlab.internal.parallel.threads.getLogicalPoolSessionId();
            if isempty(STORE)
                STORE = dictionary(string.empty(), parallel.internal.constant.ConstantStore.empty());
            end
            if ~isKey(STORE, poolSessionId)
                STORE(poolSessionId) = parallel.internal.constant.ConstantStore();
                mlock;
            end
            obj = STORE(poolSessionId);
        end

        function reset()
            % Reset all Constant data for this MVM.
            parallel.internal.constant.ConstantStore.getInstance("reset");
        end
    end

    methods (Hidden, Static)
        function [ids, values] = getAll()
            % For test purposes only
            store = parallel.internal.constant.ConstantStore.getInstance();
            ids = keys(store.DataMap);
            values = cell(size(ids));
            for ii = 1:numel(ids)
                entry = store.getEntry(ids(ii));
                values{ii} = entry.getValue();
            end
        end
    end
end
