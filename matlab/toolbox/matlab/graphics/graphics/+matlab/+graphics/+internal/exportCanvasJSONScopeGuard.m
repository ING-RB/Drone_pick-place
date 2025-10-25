classdef exportCanvasJSONScopeGuard < handle
%

%   Copyright 2024 The MathWorks, Inc.

    properties (Access=private)
        Commands (1,:) cell
    end
    methods
        function addCallback(obj,fcn)
            arguments
                obj matlab.graphics.internal.exportCanvasJSONScopeGuard
                fcn function_handle
            end
            obj.Commands{end+1}=fcn;
        end
        function delete(obj)
            for i = 1:numel(obj.Commands)
                try %#ok<TRYNC>
                    obj.Commands{i}();
                end
            end
        end
    end
end
