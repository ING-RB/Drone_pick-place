classdef (Hidden, Abstract) Identifiable
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = {?matlab.buildtool.TaskGroup, ?matlab.buildtool.internal.TaskContainer})
        Name (1,1) string {mustBeNonmissing}
    end
end

