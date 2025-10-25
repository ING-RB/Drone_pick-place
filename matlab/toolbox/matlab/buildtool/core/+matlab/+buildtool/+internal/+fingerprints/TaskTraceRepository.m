classdef TaskTraceRepository < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Abstract)
        trace = lookupTrace(repo, key)
        updateTrace(repo, key, trace)
        removeTrace(repo, key)
        traces = allTraces(repo)
        removeAllTraces(repo)
    end
end
