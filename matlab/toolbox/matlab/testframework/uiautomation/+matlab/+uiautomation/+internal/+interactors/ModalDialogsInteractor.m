classdef ModalDialogsInteractor < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 - 2024 The MathWorks, Inc.

    properties(Abstract)
        DialogType
    end

    properties(Hidden, GetAccess=protected, Constant)
        Stack = matlab.uiautomation.internal.Stack;
    end

    methods(Abstract)
        chooseDialog(obj, varargin);
        dismissDialog(obj, varargin);
    end

    methods(Access=protected)
        function cleaner = registerFunctionHandleToStack(obj, fcn)
            % Check if the feature is empty before assigning cleaner
            % To ensure only empty feature('WaitForBypassFcn') at last step
            if isempty(feature('WaitForBypassFcn'))
                cleaner = onCleanup(@obj.cleanState);
            else
                cleaner = onCleanup(@emptyFcn);
            end

            fh = obj.getStackableFunction(fcn);
            % Register fh to WaitForBypassFcn service
            % After registration, when Matlab thread is blocked,
            % fh will be executed
            feature('WaitForBypassFcn', fh);
            
            % Set isTestToolUsed to true for dialog batch mode query purpose
            prevState = matlab.ui.internal.utils.BatchModeHelper.isTestToolUsed(true);
            % Reset isTestToolUsed to previous state during cleanup phase
            cleaner(end + 1) = onCleanup(@() matlab.ui.internal.utils.BatchModeHelper.isTestToolUsed(prevState));
        end

        function throwNotSupported(obj,gesture)
            error(message('MATLAB:uiautomation:Driver:GestureNotSupportedForDialog', ...
                gesture, obj.DialogType));
        end
    end

    methods(Access=private)
        function cleanState(obj)
            % Reset WaitForBypssFcn
            feature('WaitForBypassFcn', []);

            if ~isempty(obj.Stack.peek)
                % Throw warning if there is still any gesture in Stack during
                % cleanup
                warning( message('MATLAB:uiautomation:Driver:NotAllDialogGesturesPerformed') );
                % Empty the Stack
                while ~isempty(obj.Stack.pop)
                end
            end

        end

        function popStackAndExecuteFcn(obj,varargin)
            fh = obj.Stack.pop;
            if isempty(fh)
                % Throw error if blocking dialog is created but no unblock function
                % in Stack to unblock
                error( message('MATLAB:uiautomation:Driver:NeedsToUnblockDialog') );
            else
                fh(varargin{:});
            end
        end

        function newFcn = getStackableFunction(obj,fcn)
            % Push unblock function fcn to a Stack and
            % return a function handle
            % when the function handle gets executed,
            % it will pop the top function handle from the Stack
            % and execute it

            obj.Stack.push(fcn);
            newFcn = @obj.popStackAndExecuteFcn;
        end
    end
end

function emptyFcn
end
