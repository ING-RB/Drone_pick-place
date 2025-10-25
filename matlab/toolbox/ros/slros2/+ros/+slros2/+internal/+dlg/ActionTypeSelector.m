classdef ActionTypeSelector < ros.internal.dlg.ActionTypeSelector
%This class is for internal use only. It may be removed in the future.

%   Copyright 2023 The MathWorks, Inc.

    methods
        function obj = ActionTypeSelector()
            obj.Title = message('ros:slros2:actselector:ActionTypeDialogTitle').getString;
        end
    end

    methods (Access = protected)
        function setActionList(obj)
            obj.ActionList = ros.slros2.internal.block.MessageBlockMask.getActionList;
            assert(numel(obj.ActionList)>0, 'Expected non-empty action list');
        end
    end

    methods (Hidden)
        function dlgstruct = getDialogSchema(obj)
            actlist.Name = '';
            actlist.Type = 'listbox';
            actlist.Entries = obj.ActionList;
            actlist.Tag = 'rosacttypelist';
            actlist.MultiSelect = false;
            actlist.ObjectMethod = 'dlgCallback'; % call method on UDD source object
            actlist.MethodArgs = {'%dialog', '%tag', '%value'}; % object handle is implicit first arg
            actlist.ArgDataTypes = {'handle', 'string', 'mxArray'}; % 'handle' is type of %dialog
            actlist.Value = 0;
            actlist.NameLocation = 2; % top left

            % Main dialog
            dlgstruct.DialogTitle = obj.Title;
            dlgstruct.HelpMethod = 'ros.slros.internal.helpview';
            dlgstruct.HelpArgs = {'ros2ActionTypeSelectDlg'}; % doc id
            dlgstruct.CloseMethod = 'dlgClose';
            dlgstruct.CloseMethodArgs = {'%closeaction'};
            dlgstruct.CloseMethodArgsDT = {'string'};

            % Make this dialog modal wrt to other DDG dialogs
            % (i.e. doesn't block MATLAB command line)
            dlgstruct.Sticky = true;

            % Buttons to show on dialog (these are options to pass to DDG,
            % not the final strings, so there is no need to use message
            % catalog)
            dlgstruct.StandaloneButtonSet =  ...
                {'Ok', 'Cancel', 'Help'}; % also available: 'Revert', 'Apply'

            dlgstruct.Items = {actlist};
        end
    end
end