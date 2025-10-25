function f = files(plan, paths)
% FILES - Create file collection
%
%   F = FILES(PLAN,PATHS) creates a file collection of the specified PATHS
%   from the PLAN root folder, and returns it as a
%   matlab.buildtool.io.FileCollection object.
%
%   Specified paths can include the * and ** wildcard characters:
%
%   - The * wildcard can appear in both the filename and the pathname. It
%   matches any number of characters, including zero characters.
%
%   - The ** wildcard can appear in the pathname, but not in the filename.
%   Characters next to a ** wildcard must be file separators. It matches
%   any number of characters, including zero characters. You can use this
%   wildcard to represent subfolders of a specified folder recursively.
%
%   When you specify a path using wildcard characters, the path does not
%   match any files or folders that start with a dot (.) unless the path
%   itself starts with a dot. In addition, a path that ends with a file
%   separator matches only folders.
%
%   Example:
%
%      % Import the Task class.
%      import matlab.buildtool.Task
%
%      % Create a plan with no tasks.
%      plan = buildplan;
%
%      % Add a task that obfuscates all .m files in the folder "src".
%      plan("pcode") = Task( ...
%          Inputs=files(plan,"src/**/*.m"), ...
%          Outputs=files(plan,"src/**/*.p"), ...
%          Actions=@(ctx)pcode(ctx.Inputs.paths{:},"-inplace"));
%
%      % Run the task.
%      run(plan,"pcode");
%
%      % Run the task again. The build runner skips the task because none
%      % of the input or output files has changed since the last run.
%      run(plan,"pcode");
%
%      % Delete the .p files.
%      delete(plan("pcode").Outputs.paths{:})
%
%      % Run the task again. The build runner runs the task because the
%      % output files no longer exist.
%      run(plan,"pcode");
%
%   See also matlab.buildtool.io.FileCollection, matlab.buildtool.Task, BUILDPLAN

%   Copyright 2022-2023 The MathWorks, Inc.

arguments
    plan (1,1) matlab.buildtool.Plan
    paths string {mustBeNonzeroLengthText}
end

import matlab.buildtool.io.FileCollection;
import matlab.buildtool.internal.io.absolutePath;

absPaths = absolutePath(paths, plan.RootFolder);

tf = endsWith(paths, [filesep(),"/"]);
absPaths(tf) = absPaths(tf) + filesep();

f = FileCollection.fromPaths(absPaths);
end

% LocalWords:  subfolders buildplan inplace
