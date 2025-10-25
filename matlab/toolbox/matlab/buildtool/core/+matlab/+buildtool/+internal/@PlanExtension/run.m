function result = run(plan, varargin)
import matlab.buildtool.BuildRunner;

[taskName, taskArgs, options] = matlab.buildtool.internal.parseRunArgs(plan, varargin{:});

runner = BuildRunner.withDefaultPlugins();
runArgs = namedargs2cell(options);
result = runner.run(plan, taskName, taskArgs, runArgs{:});
end

% Copyright 2022-2023 The MathWorks, Inc.
