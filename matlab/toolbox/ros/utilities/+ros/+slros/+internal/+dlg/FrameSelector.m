classdef FrameSelector < ros.internal.dlg.FrameSelector
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2023 The MathWorks, Inc.

    properties
        ROSMaster
    end

    methods
        function obj = FrameSelector()
            obj.ROSMaster = ros.slros.internal.sim.ROSMaster();
            obj.ROSMaster.verifyReachable();
        end
    end

    methods (Access=protected)
        function setFrame(obj,~)
            obj.ROSMaster.verifyReachable();
            obj.FrameList = obj.ROSMaster.getFrames();
            if numel(obj.FrameList) < 1
                error(message('ros:slros:frameselector:NoFramesAvailable', ...
                    obj.ROSMaster.MasterURI));
            end
        end
    end

    methods (Hidden)
        function dlgstruct = getDialogSchema(obj)
            framelist.Name = '';
            framelist.Type = 'listbox';
            framelist.Entries = obj.FrameList;
            framelist.Tag = 'framelist';
            framelist.MultiSelect = false;
            framelist.ObjectMethod = 'dlgCallback'; % call method on UDD source object
            framelist.MethodArgs = {'%dialog', '%tag', '%value'}; % object handle is implicit first arg
            framelist.ArgDataTypes = {'handle', 'string', 'mxArray'}; % 'handle' is type of %dialog
            framelist.Value = 0;
            framelist.NameLocation = 2; % top left

            % Main dialog
            dlgstruct.DialogTitle = message('ros:slros:frameselector:DialogTitle').getString;
            dlgstruct.HelpMethod = 'ros.slros.internal.helpview';
            dlgstruct.HelpArgs = {'rosFrameSelectDlg'}; % doc topic id
            dlgstruct.CloseMethod = 'dlgClose';
            dlgstruct.CloseMethodArgs = {'%closeaction'};
            dlgstruct.CloseMethodArgsDT = {'string'};

            % Make this dialog modal wrt other DDG dialogs
            % (doesn't block MATLAB command line)
            dlgstruct.Sticky = true;

            % Buttons to show on dialog (these are options to pass to DDG,
            % not the final strings, so there is no need to use message
            % catalog)
            dlgstruct.StandaloneButtonSet = ...
                {'Ok', 'Cancel', 'Help'}; % also available: 'Revert','Apply'
            dlgstruct.Items = {framelist};
        end
    end
end