function plot(plan, varargin)
import matlab.buildtool.TaskGraph;

graph = TaskGraph.fromPlan(plan);
graph.plot(varargin{:});
end

% Copyright 2021-2023 The MathWorks, Inc.
