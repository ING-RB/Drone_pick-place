%CONSTANTASSISTANT Used to broadcast Constant entries to pool workers.

% Copyright 2022-2024 The MathWorks, Inc.

classdef (Abstract) ConstantAssistant < handle

    methods (Abstract)
        % Send the same Constant to all pool workers
        broadcastConstant(obj, pool, id, entry);

        % Build a Constant from an existing Composite
        buildFromComposite(obj, id, entry);

        % Clear the Constant on all pool workers
        clearConstant(obj, pool, id);
    end

    methods (Access = protected)
        % Shared helper to asynchronously schedule remote cleanup and
        % issue any errors as warnings
        function scheduleCleanup(~, pool, id)
            try
                f = parfevalOnAll(pool, @parallel.internal.constant.remoteCleanup, 1, id);
                f.afterEach(@iHandleCleanupError,0);
            catch
                % Pool may have become invalid (e.g. lost worker), don't report this.
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iHandleCleanupError(err)

if ~isempty(err)
    % Only report unique errors.
    ids = {err.identifier};
    [~,idx] = unique(ids);
    uniqueExceptions = err(idx);

    for i = 1:numel(uniqueExceptions)
        parallel.internal.warningNoBackTrace(message('MATLAB:parallel:constant:ConstantErrorsDuringCleanup', ...
            uniqueExceptions(i).message));
    end
end

end
