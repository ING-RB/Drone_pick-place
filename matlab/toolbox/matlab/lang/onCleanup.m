classdef onCleanup < handle
    properties(SetAccess = 'private', GetAccess = 'public', Transient)
        task (1, 1) function_handle = @defaultTask;
    end

    methods
        function obj = onCleanup(task)
            arguments
                task (1, 1) function_handle = @defaultTask;
            end
            obj.task = task;
        end

        function cancel(obj)
            obj.task = @canceledTask;
        end
    end
    
    methods (Hidden = true)
        function obj = saveobj(obj)
            persistent haveAlreadyWarned;
            if isempty(haveAlreadyWarned)
                warning(message('MATLAB:onCleanup:DoNotSave'));
                haveAlreadyWarned = true;
            end
        end

        function delete(obj)
            obj.task();
        end
    end
end

function defaultTask
end

function canceledTask
end

%#codegen

%   Copyright 2007-2024 The MathWorks, Inc.
