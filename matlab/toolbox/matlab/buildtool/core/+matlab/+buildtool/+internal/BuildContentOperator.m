classdef BuildContentOperator < handle & matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods (Abstract, Access = protected)
        runTaskGraph(operator, pluginData)
        fixture = createBuildFixture(operator, pluginData)
        setupBuildFixture(operator, pluginData)
        teardownBuildFixture(operator, pluginData)
        context = createTaskContext(operator, pluginData)
        runTask(operator, pluginData)
        runTaskAction(operator, pluginData)
        skipTask(operator, pluginData)
    end
end

