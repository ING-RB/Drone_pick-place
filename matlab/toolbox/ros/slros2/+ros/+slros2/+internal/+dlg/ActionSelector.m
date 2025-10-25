classdef ActionSelector < ros.internal.dlg.ActionSelector
%This class is for internal use only. It may be removed in the future.

%   Copyright 2023 The MathWorks, Inc.

    methods
        function obj = ActionSelector()
            obj.Title = message('ros:slros2:actselector:ActionDialogTitle').getString;
        end
    end

    methods (Access = protected)
        function setActionListAndTypes(obj)

            [obj.ActionList, obj.ActionTypeList] = ros.ros2.internal.NetworkIntrospection.getActionNamesTypes();
            if numel(obj.ActionList) < 1
                error(message('ros:slros2:actselector:NoActionsAvailable'));
            end
        end
    end

    methods (Hidden)
        function dlgstruct = getDialogSchema(obj)
            actlist.Name = '';
            actlist.Type = 'listbox';
            actlist.Entries = obj.ActionList;
            actlist.Tag = 'rosactionlist';
            actlist.MultiSelect = false;
            actlist.ObjectMethod = 'dlgCallback'; % call method on UDD source object
            actlist.MethodArgs = {'%dialog', '%tag', '%value'}; % object handle is implicit first arg
            actlist.ArgDataTypes = {'handle', 'string', 'mxArray'}; % 'handle' is type of %dialog
            actlist.Value = 0;
            actlist.NameLocation = 2; % top left

            % Main dialog
            dlgstruct.DialogTitle = obj.Title;
            dlgstruct.HelpMethod = 'ros.slros.internal.helpview';
            dlgstruct.HelpArgs = {'ros2ActionSelectDlg'}; % doc topic id
            dlgstruct.CloseMethod = 'dlgClose';
            dlgstruct.CloseMethodArgs = {'%closeaction'};
            dlgstruct.CloseMethodArgsDT = {'string'};

            % Make this dialog modal w.r.t to other DDG dialogs
            % (i.e. doesn't block MATLAB command line)
            dlgstruct.Sticky = true;

            % Buttons to show on dialog (these are options to pass to DDG,
            % not the final strings, so there is no need to use action
            % catalog)
            dlgstruct.StandaloneButtonSet = ...
                {'Ok', 'Cancel', 'Help'}; % also available: 'Revert', 'Apply'
            dlgstruct.Items = {actlist};
        end
    end
end