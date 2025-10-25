classdef (Abstract) ActionSelector < handle
%This class is for internal use only. It may be removed in the future.

%  ActionSelector (abstract) opens a DDG dialog that lets the user select
%  from a list of available ROS actions (shared between ROS 1 and ROS 2).
%  Once the user accepts the changes (or cancels the dialog), a callback is
%  invoked with the closure action and selected topic type.

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = protected)
        Title = message('ros:slros:actselector:ActionDialogTitle').getString;
        ROSAction = ''
        ROSActionType = ''
        ActionList = {} % list of available topics
        ActionTypeList = {} % action type corresponding to each action
        CloseFcnHandle = function_handle.empty
    end

    methods (Access = protected, Abstract)
        % Sub-classes must implement the following methods
        setActionListAndTypes(obj);
    end

    methods
        function dlg = openDialog(obj, closeFcnHandle)
        % closeFcnHandle: handle to function that takes three arguments
        %   closeFcn(isAcceptedSelection, rosAction, rosActionType)
        %    isAccpectedSelection: true if user clicked on 'ok', false if
        %         user clicked on 'cancel' or closed window.
        %    rosAction: last selected ROS Action (string)
        %    rosActionType: type of the last selected ROS Action (string)

            validateattributes(closeFcnHandle,{'function_handle'},{'scalar'});
            obj.CloseFcnHandle = closeFcnHandle;
            setActionListAndTypes(obj);
            dlg = DAStudio.Dialog(obj);
            dlg.setWidgetValue('rosactionlist', 0); % select first item in the list
            obj.ROSAction = obj.ActionList{1};
            obj.ROSActionType = obj.ActionTypeList{1};
        end
    end

    methods (Hidden)
        function dlgCallback(obj, dlg, tag, value)
        % dlgCallback Called when user selects an item from the list

            obj.ROSAction = obj.ActionList{value+1}; % value is zero-based
            obj.ROSActionType = obj.ActionTypeList{value+1};
            dlg.refresh;
        end

        function dlgClose(obj, closeaction)
        % dlgClose Called when user close the DDG dialog
        %   closeaction is 'ok' if user clicked OK,
        %       'cancel' if user clicked cancel or closed window

            if ~isempty(obj.CloseFcnHandle)
                isAcceptedSelection = strcmpi(closeaction, 'ok');
                try
                    feval(obj.CloseFcnHandle, isAcceptedSelection, obj.ROSAction, obj.ROSActionType);
                catch
                    % Absorb all errors. If they are propagated back to
                    % DDG, this causes MATLAB to crash (Can't convert to
                    % warnings are not as they are not displayed either).
                end
            end
        end
    end
end