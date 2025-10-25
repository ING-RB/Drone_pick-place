function [status, names, err] = taskNames(file) %#ok<INUSD>
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2024 The MathWorks, Inc.

try
    [~, plan] = evalc("matlab.buildtool.Plan.load(file, LoadProject=false);");
catch e
    status = false;
    err = e;
    switch e.identifier
        case "MATLAB:buildtool:Plan:BuildFileNotFound"
            names = "MISSING";
        otherwise
            names = "INVALID";
    end
    return;
end

status = true;
names = sort([plan.Tasks.Name]);
err = [];
end
