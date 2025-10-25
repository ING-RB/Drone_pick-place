% ThreadsConstantAssistant - Implementation of ConstantAssistant for
% thread-based pools

% Copyright 2022-2024 The MathWorks, Inc.

classdef ThreadsConstantAssistant < parallel.internal.constant.ConstantAssistant

    methods
        function broadcastConstant(~, pool, id, entry)
            % Just use parfevalOnAll to send to workers
            parfevalOnAll(pool, @parallel.internal.constant.remoteStore, 0, id, entry);
        end

        function buildFromComposite(~, id, arg)
            spmd
                % Store an entry on each of the workers.
                entry = parallel.internal.constant.ConstantEntry(id, arg);
                parallel.internal.constant.remoteStore(id, entry);
            end
        end

        function clearConstant(obj, pool, id)
            obj.scheduleCleanup(pool, id)
        end
    end
end
