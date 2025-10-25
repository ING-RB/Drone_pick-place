classdef SelectRMWImplementation < matlab.hwmgr.internal.hwsetup.SelectionWithDropDown
    % SelectRMWImplementation - Screen implementation to enable users to select the
    % ROS middleware implementation.
    
    %   Copyright 2022 The MathWorks, Inc.
    
    properties
        % HelpForSelection - Cell array strings/character-vectors for
        % providing more information about the selected item. This will be
        % rendered in the "About Your Selection" section in the HelpText
        % panel
        HelpForSelection = {};
    end
    
    methods
        function obj = SelectRMWImplementation(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithDropDown(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:SelectRMWConfigurationTitle').getString;
            
            % Set the Dropdown Items      
            arch = computer('arch');
            switch (arch)
                case 'win64'
                    % Eclipse iceoryx is not supported on windows
                    obj.SelectionDropDown.Items = {message('ros:mlros2:rmwsetup:RMWConnextdds').getString,...
                        message('ros:mlros2:rmwsetup:OtherRMW').getString};
                case {'glnxa64', 'maci64'}
                    obj.SelectionDropDown.Items = {message('ros:mlros2:rmwsetup:RMWConnextdds').getString,...
                        message('ros:mlros2:rmwsetup:RMWIceoryxCpp').getString, ...
                        message('ros:mlros2:rmwsetup:OtherRMW').getString};
                case 'maca64'
                    obj.SelectionDropDown.Items = {message('ros:mlros2:rmwsetup:OtherRMW').getString};
            end
            
            % Select the first entry in DropDown - rmw_fastrtps_cpp
            obj.SelectionDropDown.ValueIndex = 1;
            obj.SelectionDropDown.Position = [165 330 181 22];
            obj.Workflow.RMWImplementation = obj.SelectionDropDown.Value;
            
            obj.SelectionDropDown.ValueChangedFcn = @obj.changeRMWImplementation;
            
            % Set the Label text
            obj.SelectionLabel.Text = message('ros:mlros2:rmwsetup:SelectRMWConfigurationLabel').getString;
            obj.SelectionLabel.Position = [20 326 150 22];
            obj.SelectionLabel.FontWeight = 'bold';
            obj.SelectedImage.Visible = 'off';

            % Removed the Description text area
            obj.Description.Text = '';
            
            % Set the What To Consider section of the HelpText
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:SelectRMWWhatToConsider').getString;

            % Set the default About Selection HelpText for FastDDS
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:SelectRMWConnextProDDS').getString;
            
            % Set the HelpForSelection property to update the HelpText
            % when the Item in the DropDown changes
            obj.HelpForSelection = {message('ros:mlros2:rmwsetup:SelectRMWConnextProDDS').getString,...
                message('ros:mlros2:rmwsetup:RMWIceoryxHelpText').getString};     
        end

        function set.HelpForSelection(obj, helptext)
            % HelpForSelection property should be specified as a cell array of
            % strings or character vectors
            assert(iscellstr(helptext), 'HelpForSelection property should be specified as a cell array of strings or character vectors'); %#ok<ISCLSTR> 
            obj.HelpForSelection = helptext;
        end
        
        function reinit(obj)
           obj.Workflow.RMWImplementation = obj.SelectionDropDown.Value;
           obj.enableScreen;
        end

        function changeRMWImplementation(obj, ~, ~)
            % CHANGERMWIMPLEMENTATION - Callback for the DropDown that changes the
            % rmw implementation based on the index of the selected item in the
            % dropdown
            
            % Save the selected RMW Implementation to the Workflow class
            obj.Workflow.RMWImplementation = obj.SelectionDropDown.Value;

            if ~isempty(obj.HelpForSelection) && ~isequal(obj.SelectionDropDown.Value, 'other')
                if  obj.SelectionDropDown.ValueIndex <= numel(obj.HelpForSelection)
                    % If the HelpForSelection has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the HelpText property
                    obj.HelpText.AboutSelection = ...
                        obj.HelpForSelection{obj.SelectionDropDown.ValueIndex};
                else
                    obj.HelpText.AboutSelection = '';
                end
            end

            if isequal(obj.SelectionDropDown.Value, 'other')
                obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:SelectCustomRMWAboutSelection').getString;
            end
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:SelectRMWWhatToConsider').getString;
        end

        function out = getNextScreenID(obj)
            switch (obj.Workflow.RMWImplementation)
                case {message('ros:mlros2:rmwsetup:RMWConnextdds').getString}
                    [out, status] = obj.getRMWConfigAvailableNextScreen;
                    if status == 0
                        out = 'ros.internal.rmwsetup.ValidateRTIDDSInstallation';
                    end
                case {message('ros:mlros2:rmwsetup:RMWIceoryxCpp').getString}
                    [out, status] = obj.getRMWConfigAvailableNextScreen;
                    if status == 0
                        out = 'ros.internal.rmwsetup.ValidateIceoryxInstallation';
                    end
                otherwise
                    out = 'ros.internal.rmwsetup.ValidateRMWImplementation';
            end
        end

        function [out, status] = getRMWConfigAvailableNextScreen(obj)
            customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance();
            customRMWList = customRMWRegistry.getRMWList();
            status = 0;
            out = '';
            if ismember(obj.Workflow.RMWImplementation, customRMWList)
               out = 'ros.internal.rmwsetup.ReconfigureRMW';
               status = 1;
            end
        end
    end
end