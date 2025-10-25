classdef FrameSelector < ros.internal.dlg.FrameSelector
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2023 The MathWorks, Inc.

    methods (Access=protected)
        function setFrame(obj, modelName)
            modelState = ros.slros.internal.sim.ModelStateManager.getState(modelName, 'create');
            if isempty(modelState.ROSNode) || ~isvalid(modelState.ROSNode)
                modelState.ROSNode = ros2node([modelName '_' num2str(randi(1e5,1))], ...
                                              ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                                              'RMWImplementation', ...
                                               ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
            end
            % Create a temporary ros2tf object
            tempTf = ros2tf(modelState.ROSNode);

            % Make three attempts to query for available frames since
            % TransformationTree may require additional time to be
            % registered in network
            frames = tempTf.AvailableFrames;
            for i=1:2
                if isempty(frames)
                    pause(1);
                    frames = tempTf.AvailableFrames;
                end
            end
            obj.FrameList = frames;
            if numel(obj.FrameList) < 1
                error(message('ros:slros2:frameselector:NoFramesAvailable'));
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
            dlgstruct.DialogTitle = message('ros:slros2:frameselector:DialogTitle').getString;
            dlgstruct.HelpMethod = 'ros.slros.internal.helpview';
            dlgstruct.HelpArgs = {'ros2FrameSelectDlg'}; % doc topic id
            dlgstruct.CloseMethod = 'dlgClose';
            dlgstruct.CloseMethodArgs = {'%closeaction'};
            dlgstruct.CloseMethodArgsDT = {'string'};

            % Make this dialog modal wrt other DDG dialogs
            % (doesn't block MATLAB command line)
            dlgstruct.Sticky = true;

            % Cuttons to show on dialog (these are options to pass to DDG,
            % not the final strings, so there is no need to use message
            % catalog)
            dlgstruct.StandaloneButtonSet = ...
                {'Ok', 'Cancel', 'Help'}; % also available: 'Revert','Apply'
            dlgstruct.Items = {framelist};
        end
    end
end