classdef TabCompletion
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    methods (Static)
        function names = nameChoices()
            plan = loadPlanIfPossible();
            names = [plan.allTasks().Name string.empty()];
        end
    end
end

function plan = loadPlanIfPossible()
try
    file = matlab.buildtool.internal.findBuildFile(); %#ok<NASGU>
    
    % evalc to suppress any command window output in plan
    evalc("plan = matlab.buildtool.Plan.load(file, LoadProject=false);");
catch
    plan = matlab.buildtool.Plan.withRootFolder(pwd());
end
end
