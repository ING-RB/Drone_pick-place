classdef (Abstract) FrameSelector < handle
%This class is for internal use only. It may be removed in the future.

%   FrameSelector (abstract) opens a DDG dialog that lets the user select
%   from a list of available frames published to /tf and /tf_static topic
%   (shared between ROS 1 and ROS 2). Once the user accepts the changes (or
%   cancels the dialog), a callback is invoked with the closure action and
%   selected frame.

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=protected)
        Frame = ''
        FrameList = {}   % list of available frames
        CloseFcnHandle = function_handle.empty
    end

    methods (Access=protected, Abstract)
        % Sub-classes must implement following methods
        setFrame(obj);
    end

    methods
        function dlg = openDialog(obj, closeFcnHandle, modelName)
        % closeFcnHandle: handle to function that takes two arguments
        %   closeFcn(isAcceptedSelection, frame)
        %       isAcceptedSelection: true of user clicked on 'ok', false if
        %           user clicked on 'cancel' or closed window
        %       frame: last selected frame (string)
        % modelName: name of the model, this is required to reuse the
        % existed Simulink ROS/ROS 2 node

            validateattributes(closeFcnHandle, {'function_handle'},{'scalar'});
            obj.CloseFcnHandle = closeFcnHandle;
            setFrame(obj, modelName);
            dlg = DAStudio.Dialog(obj);
            dlg.setWidgetValue('framelist', 0); % select first item in the list
            % Only set initial frame to the first frame if frame list is
            % not empty
            if ~isempty(obj.FrameList)
                obj.Frame = obj.FrameList{1};
            end
        end
    end

    methods (Hidden)
        function dlgCallback(obj, dlg, tag, value) %#ok<INUSD>
        % dlgCallback: Called when user selects an item from the list
            obj.Frame = obj.FrameList{value+1}; % value is zero-based
            dlg.refresh;
        end
    
        function dlgClose(obj, closeaction)
        % dlgClose: closeaction is 'ok' if user clocked OK
        %           'cancel' if user clicked cancel or closed window
            if ~isempty(obj.CloseFcnHandle)
                isAcceptedSelection = strcmpi(closeaction, 'ok');
                try
                    feval(obj.CloseFcnHandle, isAcceptedSelection, obj.Frame);
                catch
                    % Absorb all errors. If they are propagated back to
                    % DDG, this causes MATLAB to crash, (Can't convert to
                    % warnings as they are not displayed either).
                end
            end
        end

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