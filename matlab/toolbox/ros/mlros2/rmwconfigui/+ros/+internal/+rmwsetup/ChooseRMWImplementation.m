classdef ChooseRMWImplementation < matlab.hwmgr.internal.hwsetup.SelectionWithDropDown
    % ChooseRMWImplementation - Screen implementation to enable users to choose the
    % ROS middleware implementation, if there are multiple RMW implementations 
    % available for a particular middleware.
    
    %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties
        % ScreenInstructions - Instructions on the screen
        ScreenInstructions

        % NextActionText - Text showing Next screen action
        NextActionText
    end

    properties(Access = private)
        % PkgSelectionMap - Map from selected key to RMW implementation
        PkgSelectionMap

        % SelectedDropDownValue - selected value in the dropdown
        SelectedDropDownValue
    end
    
    methods
        function obj = ChooseRMWImplementation(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithDropDown(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:ChooseRMWPackageScreenTitle').getString;

            % Set Description Properties
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenInstructions.Position = [20 330 430 50];
            obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:ChooseRMWPackageScreenInstructions').getString;

            % Set the Label text
            obj.SelectionLabel.Text = message('ros:mlros2:rmwsetup:RMWPackageSelectionLabel').getString;
            obj.SelectionLabel.Position = [20 300 220 22];
            obj.SelectionLabel.FontWeight = 'bold';
            obj.SelectedImage.Visible = 'off';
            
            obj.PkgSelectionMap = containers.Map;
            session = obj.Workflow.getSession;
            session('PkgSelectionMap') = obj.PkgSelectionMap; %#ok<NASGU>

            obj.populateDropDownItems();
            obj.SelectionDropDown.Position = [250 304 165 22];
            obj.SelectionDropDown.ValueChangedFcn = @obj.selectPackagesToBuild;

            % Removed the Description text area
            obj.Description.Text = '';

            obj.NextActionText = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.NextActionText.Position = [30 10 410 30];
            obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionDynamic').getString;

            % Set the What To Consider section of the HelpText
            obj.HelpText.WhatToConsider = '';

            % Set the default About Selection HelpText for FastDDS
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:ChooseRMWPackageScreenAboutSelection').getString;
        end

        function populateDropDownItems(obj)
            obj.SelectionDropDown.Items = {};
            session = obj.Workflow.getSession;
            rmwPackagesMap = session('RMWTypeSupportMap');
            obj.SelectionDropDown.Items = unique(rmwPackagesMap.keys);
            obj.SelectionDropDown.Items{end+1} = 'all';

            if ~isKey(session, 'PkgSelectionMap')
                obj.PkgSelectionMap = containers.Map;
                session('PkgSelectionMap') = obj.PkgSelectionMap;
            end
            pkgSelectionMap = session('PkgSelectionMap');
            if isempty(pkgSelectionMap.keys)
                for key=1:numel(obj.SelectionDropDown.Items)
                    if isequal(rmwPackagesMap(obj.SelectionDropDown.Items{key}),'dynamic')
                        % default the drop down value to rmw implementation
                        % containing dynamic type support.
                        obj.SelectionDropDown.ValueIndex = key;
                        break;
                    end
                end
                obj.SelectedDropDownValue = obj.SelectionDropDown.Value;
            else
                key = find(ismember(obj.SelectionDropDown.Items, obj.SelectedDropDownValue));
                obj.SelectionDropDown.ValueIndex = key;
            end

            if ~isequal(obj.SelectionDropDown.Value, 'all')
                % Here, store the drop down and user selection values
                % except "all" option in a map. This will be used in build
                % RMW implementation screen, where the selected package
                % needs will be built.
                obj.PkgSelectionMap(obj.SelectionDropDown.Value) = obj.SelectionDropDown.Value;
                obj.Workflow.RMWImplementation = obj.SelectionDropDown.Value;
            end
        end
        
        function selectPackagesToBuild(obj, ~, ~)
            % selectPackagesToBuild - callback executed when there is
            % change in the dropdown value of selecting a RMW
            % implementation package to build.
 
            session = obj.Workflow.getSession;
            obj.PkgSelectionMap = containers.Map;
            session('PkgSelectionMap') = obj.PkgSelectionMap;
            typesupportMap = session('RMWTypeSupportMap');
            if ~isequal(obj.SelectionDropDown.Value, 'all')
                obj.PkgSelectionMap(obj.SelectionDropDown.Value) = obj.SelectionDropDown.Value;
            else
                rmwPkgNames = session('RMWLocationToPackagesMap');
                rmwImpls = rmwPkgNames.values;

                appendedRMW = [];
                for i=1:numel(rmwImpls{1})
                    appendedRMW = [appendedRMW, rmwImpls{1}{i}, ' ']; %#ok<AGROW>
                end
                % Here, store "all" option in a map, with value as space
                % seperated RMW implementations available in the RMW package
                % location provided in validate RMW implementation package
                % screen.
                obj.PkgSelectionMap('all') = appendedRMW;
            end
            obj.SelectedDropDownValue = obj.SelectionDropDown.Value;
            if isequal(obj.SelectionDropDown.Value, 'all') || ...
                    isequal('static', typesupportMap(obj.SelectionDropDown.Value))
                obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionStatic').getString;
            else
                obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionDynamic').getString;
            end
        end

        function reinit(obj)
            obj.populateDropDownItems();
            obj.enableScreen();
        end

        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.ValidateRMWImplementation';
        end

        function out = getNextScreenID(obj)
            session = obj.Workflow.getSession;
            typesupportMap = session('RMWTypeSupportMap');
            rmwPkgNames = session('RMWLocationToPackagesMap');
            rmwImpls = rmwPkgNames.values;
            hasStatic = false;
            for i=1:numel(rmwImpls{1})
                if isequal(typesupportMap(rmwImpls{1}{i}), 'static')
                    hasStatic = true;
                    break;
                end
            end

            if (isequal(obj.SelectionDropDown.Value,'all') && hasStatic) || ...
                    isequal(typesupportMap(obj.SelectionDropDown.Value), 'static')
                out = 'ros.internal.rmwsetup.ValidateROSIDLTypeSupport';
            else
                out = 'ros.internal.rmwsetup.MiddlewareInstallationEnvironment';
            end
        end
    end
end