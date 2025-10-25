%parallel.internal.parfor.ThreadsParforEngine
% PARFOR engine for thread-based pools

% Copyright 2023-2024 The MathWorks, Inc.

classdef ThreadsParforEngine < parallel.internal.parfor.Engine

    properties (GetAccess = private, SetAccess = immutable)
        Pool
        Controller
        NumWorkers (1,1) double
    end

    properties (GetAccess = private, Constant)
        ForbiddenTypes = {'Composite', 'distributed'}
    end

    methods
        function obj = ThreadsParforEngine(partitionMethod, partitionSize, ...
                                           pool, maxNumWorkers, initData)
            obj@parallel.internal.parfor.Engine(partitionMethod, partitionSize);
            obj.Pool = pool;
            obj.NumWorkers = min(maxNumWorkers, pool.NumWorkers);

            % Listen for serialization events.
            [~, getListFcn] = ...
                parallel.internal.general.SerializationNotifier.createAccumulatingListener();

            obj.Controller = parallel.internal.pool.ThreadsParforController(pool, obj.NumWorkers, initData);

            % Error if we're trying to send a Composite to a worker.
            savedClasses = getListFcn();
            if ~isempty(savedClasses) && any(ismember(parallel.internal.parfor.ThreadsParforEngine.ForbiddenTypes, savedClasses))
                error(message('parallel:lang:parfor:IllegalComposite'));
            end
        end

        function [initDispatchSize, normalDispatchSize] = getDispatchSizes(~, numIntervals, ~)
        % Thread-based pools choose to dispatch all intervals upfront.
            initDispatchSize = numIntervals;
            normalDispatchSize = 0;
        end

        function n = getNumWorkers(obj)
            n = obj.NumWorkers;
        end

        function complete(obj, errorDetected)
            if ~errorDetected
                obj.Controller.flushDiary();
            end
        end

        function ok = addInterval(obj, tag, intervalData)
            ok = true;
            obj.Controller.addInterval(tag, intervalData);
        end

        function allIntervalsAdded(obj)
            obj.Controller.allIntervalsAdded();
        end

        function [tags, results] = getCompleteIntervals(obj, numIntervals)
            tags = zeros(numIntervals,1,"int64");
            results = cell(numIntervals, 2);
            for i = 1:numIntervals
                [results(i,:), tags(i)] = obj.Controller.fetchNextCompletedInterval();
            end
        end
    end
end
