function mustBeValidTaskName(name)
% This function is unsupported and might change or be removed without 
% notice in a future version.

%   Copyright 2024 The MathWorks, Inc.

arguments
    name string
end

tf = matlab.buildtool.internal.isTaskName(name);
if ~all(tf)
    name = fillmissing(name, "constant", "<missing>");
    error(message("MATLAB:buildtool:TaskContainer:MustBeValidTaskName", name(find(~tf,1))));
end
end