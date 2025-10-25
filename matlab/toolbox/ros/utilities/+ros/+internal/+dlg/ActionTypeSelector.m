classdef (Abstract) ActionTypeSelector < handle
%This class is for internal use only. It may be removed in the future.

%  ActionTypeSelector opens a DDG dialog that lets the user select from a
%  list of ROS action types (shared between ROS 1 and ROS 2). Once the
%  user accepts the changes (or cancels the dialog), a callback is invoked
%  with the closure action and selected action type.
%
%  Sample use:
%   selector = ros.slros2.internal.dlg.ActionTypeSelector;
%   % The first argument is the action type to select by default
%   selector.openDialog('example_interfaces/Fibonacci', ...
%   @(isAccepted,actionType) disp(actionType));

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = protected)
        Title = message('ros:slros:actselector:ActionTypeDialogTitle').getString;
        ROSAction = ''
        ActionList = {}
        CloseFcnHandle = function_handle.empty
    end

    methods (Access = protected, Abstract)
        % Sub-classes must implement the following methods
        setActionList(obj);
    end

    methods
        function obj = ActionTypeSelector()
        % Nothing to do in constructor
        end

        function set.ActionList(obj, val)
            validateattributes(val, {'cell'},{'nonempty'},'setActionList','ActionList',2);
            obj.ActionList = val;
        end

        function dlg = openDialog(obj, initialActSelection, closeFcnHandle)
        % closeFcnHandle: handle to function that takes two arguments
        %   closeFcn(isAcceptedSelection, rosAction)
        %       isAcceptedSelection: true if user clicked on 'ok', false if
        %         user clicked on 'cancel' or closed window
        %       rosAction: last selected ROS action (string)

            assert(ischar(initialActSelection) || isempty(initialActSelection));
            validateattributes(closeFcnHandle, {'function_handle'},{'scalar'});
            obj.CloseFcnHandle = closeFcnHandle;
            setActionList(obj);
            dlg = DAStudio.Dialog(obj);
            if isempty(initialActSelection)
                return;
            end

            % Find initial action selection, if any
            index = find(strcmpi(initialActSelection, obj.ActionList));
            if ~isempty(index)
                dlg.setWidgetValue('rosacttypelist', index-1); %zero-based
                obj.ROSAction = obj.ActionList{index};
            else
                warning(message('ros:slros:actselector:ActionTypeNotFound', ...
                                initialActSelection));
            end
        end
    end

    methods (Hidden)
        function dlgCallback(obj, dlg, tag, value)
        %dlgCallback Called when user selects an item from the list
            obj.ROSAction = obj.ActionList{value+1}; % value is zero-based
            dlg.refresh;
        end

        function dlgClose(obj, closeaction)
        % dlgClose Called when user close the DDG dialog
        % closeaction is 'ok' if user clicked OK,
        %   'cancel' if user clicked cancel or closed window
            if ~isempty(obj.CloseFcnHandle)
                isAcceptedSelection = strcmpi(closeaction, 'ok');
                try
                    feval(obj.CloseFcnHandle, isAcceptedSelection, obj.ROSAction);
                catch ex
                    disp(ex);
                    % Absorb all errors. If they are propagated back to
                    % DDG, this causes MATLAB to crash (Can't convert to
                    % warnings are not as they are not displayed either).
                end
            end
        end
    end
end