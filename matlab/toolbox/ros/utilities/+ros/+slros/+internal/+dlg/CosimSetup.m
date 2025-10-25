classdef CosimSetup < handle
    %This class is for internal use only. It may be removed in the future.

    %  CosimSetup opens a DDG dialog that lets the user select the
    %  world file to co-simulate and also allows them to specify the
    %  Timeout for the service call.
    %
    %  Sample use:
    %   dlg = ros.slros.internal.dlg.CosimSetup.retrieveDialog(modelName);

    %   Copyright 2024 The MathWorks, Inc.
    properties (Access = protected)
        %ModelName Name of model in which block resides, or blank if using
        %   base workspace
        ModelName = '';

        UpdatedTimeout
    end

    properties(Constant)
        ROS2PacerHelpTag = 'helptext';
        TimoutTag = 'Timeout';
        SysObjBlockName = 'ROS 2 Pacer';
    end

    properties (Access = protected, Constant)
        % DialogTagPrefix Prefix for the dialog tag, for easy searching
        DialogTagPrefix = 'slros_ros2pacer_';
    end

    methods (Static)
        
        function val = setConnectionTimeout(value)
            persistent ConnectionTimeoutValue;
            if nargin
                % validate connection timeout
                validateattributes(value, {'numeric'}, {'scalar', 'positive', 'nonnan'}, '', 'ConnectionTimeout');
                ConnectionTimeoutValue = value;
            end

            val = ConnectionTimeoutValue;
        end
        % Dialog management functions
        function dlg = retrieveDialog(modelName,varargin)
            %retrieveDialog Return the dialog for loading data to the model
            %   If the dialog exists, it will be returned, otherwise it will be
            %   opened
            %   modelName - this dialog will assign data to the specified
            %               model's workspace
            %   dlg - DAStudio.Dialog object

            dlg = findDDGByTag(strcat(ros.slros.internal.dlg.CosimSetup.DialogTagPrefix, modelName));
            if ~isempty(dlg)
                dlg = dlg(1);
                show(dlg)
            else
                obj = ros.slros.internal.dlg.CosimSetup(modelName,varargin{:});            
                dlg = openDialog(obj);
            end
        end

    end

    methods
        
        function  [isValid, msg] = preApplyCB(obj)
            %preApplyCB is called after the Ok button is pressed and before
            %the pop up window closes to verify if added values for by the
            %users are as expected or not.

            try
                % updating persistent variable
                if ~isempty(obj.UpdatedTimeout)
                    ros.slros.internal.dlg.CosimSetup.setConnectionTimeout(obj.UpdatedTimeout);
                end
                % setting output variables
                isValid = true;
                msg='success';
            catch ex
                % setting output variables
                isValid = false;
                msg= ex.message;
            end
        end

        % Callback to update Timeout
        function simTimeoutChanged(obj, value)
            % converting default string value to numeric
            value = str2double(value);
              
            obj.UpdatedTimeout = value;
        end

        % Constructor
        function obj = CosimSetup(modelName,varargin)
            obj.ModelName = modelName;
        end

        function dlg = openDialog(obj)
            %openDialog Create, lay out, and make visible the dialog window

            % Open dialog
            dlg = DAStudio.Dialog(obj);
        end

    end

    methods (Hidden)
        % Dialog layout
        function dlgstruct = getDialogSchema(obj)

            % Co-simulation dialog
            row = 1;

            timeoutLabel.Name = 'Timeout(s):';
            timeoutLabel.Type  = 'text';
            timeoutLabel.Alignment  = 7;
            timeoutLabel.RowSpan = [row row];
            timeoutLabel.ColSpan = [1 1];
            timeoutLabel.Visible = true;

            timeoutValue.Name = '';
            timeoutValue.Type = 'edit';
            % getting Connection Timeout Value from persistent variable
            v = ros.slros.internal.dlg.CosimSetup.setConnectionTimeout;
            % if persistent variable is not yet set, getting value from the
            % block and setting it.
            if isempty(v)
                v = get_param([gcb,'/',obj.SysObjBlockName],'ConnectionTimeout');
                v = str2double(v);
                ros.slros.internal.dlg.CosimSetup.setConnectionTimeout(v);
            end
            timeoutValue.Value = v;
            timeoutValue.RowSpan = [row row];
            timeoutValue.ColSpan = [2 2];
            timeoutValue.Alignment = 0; % top-left
            timeoutValue.Tag = obj.TimoutTag;
            timeoutValue.ObjectMethod = 'simTimeoutChanged'; % call method on UDD source object
            timeoutValue.MethodArgs = {'%value'}; % '%handle ' is implicit as first arg
            timeoutValue.ArgDataTypes = {'mxArray'};
            timeoutValue.Visible = true;

            row = row + 1;

            % container
            coSimContainer.Type = 'group'; % can be 'panel', in which case, case use .Flat = true
            coSimContainer.Name = 'Cosimulation Settings';
            coSimContainer.Flat = false;
            coSimContainer.LayoutGrid = [row 3]; % [numrows numcolumns]
            coSimContainer.ColStretch = [2 2 1];
            coSimContainer.Items = {timeoutLabel, timeoutValue};
            coSimContainer.Visible = true;

            % Main Dialog

            helptext.Name = message('ros:slros2:ros2pacer:CosimPopupDescription').getString();
            helptext.Type  = 'text';
            helptext.WordWrap = true;
            helptext.RowSpan = [1 1];
            helptext.ColSpan = [1 2];
            helptext.Tag = obj.ROS2PacerHelpTag;
            helptext.Visible = true;

            topLevelContainer.Type = 'group'; % can be 'panel', in which case, case use .Flat = true
            topLevelContainer.Name = '';
            topLevelContainer.Items = {helptext, coSimContainer};
            topLevelContainer.Visible = true;

            % Main dialog struct

            dlgstruct.DialogTitle = message('ros:slros2:ros2pacer:CosimDialogTitle').getString();

            %Make the dialog non-modal like other dialogs
            %there will be only one dialog
            dlgstruct.Sticky = false;

            % Buttons to show on dialog
            dlgstruct.StandaloneButtonSet =  ...
                {'Ok', 'Cancel', 'Help'};

            dlgstruct.PreApplyCallback  = 'preApplyCB';
            dlgstruct.PreApplyArgs = {obj};

            dlgstruct.Items = {topLevelContainer};
            dlgstruct.DialogTag = strcat(ros.slros.internal.dlg.CosimSetup.DialogTagPrefix, obj.ModelName);
        end
        
    end

end
