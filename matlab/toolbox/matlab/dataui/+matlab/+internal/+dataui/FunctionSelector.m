classdef (Sealed) FunctionSelector < matlab.ui.componentcontainer.ComponentContainer
    % FunctionSelector: A set controls for selecting a function from either
    % a function handle, a local function, or (optionally) a function file
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2021-2025 The MathWorks, Inc.

    properties (Access = public)
        % Controls in this component
        GridLayout
        FcnTypeDropDown
        LocalFcnDropDown
        NewFcnButton
        HandleEditField
        BrowseEditField
        BrowseButton
        % Value of function from browsing
        BrowseValue = '';
        % Default of the HandleEditField to be used to restore defaults
        HandleDefault = '';
        % Properties for new local function
        NewFcnText = '';
        NewFcnName = '';
        % Allow caller to arrange the grid
        AutoArrangeGrid = true;
        % Allow function handle input to be empty
        AllowEmpty = false;
        % Include option to browse for a function file. For full
        % functionality, this property must be set at construction.
        IncludeBrowse = false;
    end

    properties (Dependent)
        % Properties dependent on controls
        FcnType
        LocalValue
        HandleValue
        Enable
        Tooltip
        State
    end

    properties (Constant)
        IconWidth = 16;
    end

    properties (Dependent, SetAccess = private)
        % Value of component: to be used for script generation
        Value
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Set the initial position of this component
            obj.Position = [100 100 500 22];

            % Layout
            obj.GridLayout = uigridlayout(obj,...
                RowHeight = 22,...
                ColumnWidth = ["fit" "fit" "fit" "fit"],...
                Padding = 0);
            obj.FcnTypeDropDown = uidropdown(obj.GridLayout,...
                Items = {getString(message("MATLAB:dataui:fcnSelectorLocal")),...
                getString(message("MATLAB:dataui:fcnSelectorHandle")),...
                getString(message("MATLAB:dataui:fcnSelectorFromFile"))},...
                ItemsData = {'local','handle','file'},...
                ValueChangedFcn = @obj.updateAndThrowValueChanged);
            obj.LocalFcnDropDown = uidropdown(obj.GridLayout,...
                DropDownOpeningFcn = @obj.populateLocalFcnDD,...
                ValueChangedFcn = @obj.updateAndThrowValueChanged,...
                Items = {getString(message("MATLAB:ui:defaults:select"))},...
                ItemsData = {'select variable'});
            obj.LocalFcnDropDown.Layout.Column = [2 3];
            obj.NewFcnButton = uibutton(obj.GridLayout,...
                Text = string(message("MATLAB:dataui:fcnSelectorNew")) + "...",...
                ButtonPushedFcn = @obj.makeNewFcn);
            obj.HandleEditField = uieditfield(obj.GridLayout,...
                ValueChangedFcn = @obj.validateFcnHandle);
            obj.HandleEditField.Layout.Column = [2 4];
            obj.HandleEditField.Layout.Row = 1;
            obj.BrowseEditField = uieditfield(obj.GridLayout,...
                Editable = "off",...
                Placeholder = string(message("MATLAB:dataui:fcnSelectorBrowsePlaceholder")));
            obj.BrowseEditField.Layout.Column = 2;
            obj.BrowseEditField.Layout.Row = 1;
            obj.BrowseButton = uibutton(obj.GridLayout,...
                Text = "",...
                ButtonPushedFcn = @obj.browseForFile,...
                HorizontalAlignment = "left");
            matlab.ui.control.internal.specifyIconID(obj.BrowseButton,...
                "openFolder",obj.IconWidth,obj.IconWidth)
            obj.BrowseButton.Layout.Column = 3;
            obj.BrowseButton.Layout.Row = 1;
        end

        function update(obj)
            if ~obj.IncludeBrowse && matches("file",obj.FcnTypeDropDown.ItemsData)
                % Finish setup by removing Browse options when not needed
                obj.FcnTypeDropDown.Items(end) = [];
                obj.FcnTypeDropDown.ItemsData(end) = [];
            end

            % Show appropriate controls based on FcnType
            type = obj.FcnTypeDropDown.Value;
            obj.LocalFcnDropDown.Visible = matches(type,"local");
            obj.NewFcnButton.Visible = matches(type,["local" "file"]);
            obj.HandleEditField.Visible = matches(type,"handle");
            obj.BrowseEditField.Visible = matches(type,"file");
            obj.BrowseButton.Visible = matches(type,"file");
            obj.BrowseEditField.Value = obj.BrowseValue;

            if obj.AutoArrangeGrid
                matlab.internal.dataui.setParentForWidgets([obj.LocalFcnDropDown, ...
                    obj.NewFcnButton, obj.LocalFcnDropDown, obj.BrowseEditField, ...
                    obj.BrowseButton], obj.GridLayout)
                if obj.HandleEditField.Visible
                    % EditFields don't work great with 'fit'
                    % Pick a pixel width that works ok for function handles
                    obj.GridLayout.ColumnWidth{4} = 200;
                else
                    % fit the New Button
                    obj.GridLayout.ColumnWidth{4} = "fit";
                end
            elseif ~obj.IncludeBrowse
                obj.BrowseButton.Parent = [];
            end % Else caller is in control of Grid
        end
    end

    methods
        function updateAndThrowValueChanged(obj,~,~)
            update(obj);
            notify(obj,"ValueChanged");
        end

        function populateLocalFcnDD(obj,~,~)
            % DropDownOpeningFcn for local fcn dd
            % Populate dropdown with local functions in the current script
            src = obj.LocalFcnDropDown;
            oldValue = src.Value;
            % Always keep the first item: 'select'
            items = src.Items(1);
            itemsData = src.ItemsData(1);

            d = matlab.desktop.editor.getActive;
            if ~isempty(d)
                % Return the names of the local functions in the active script.
                % If the script code contains a parse error, mtree returns an empty cell
                treeFile = mtree(d.Text);
                treeFcns = mtfind(treeFile,Kind = 'FUNCTION');
                treeFcnNames = Fname(treeFcns);
                cellFcnNames = treeFcnNames.List.strings;

                % Empty the list if duplicates exist
                if numel(unique(cellFcnNames)) < numel(cellFcnNames)
                    cellFcnNames = cell(0);
                end

                src.Items = [items, cellFcnNames];
                src.ItemsData = [itemsData, cellFcnNames];
            else
                % not testable
                src.Items = items;
                src.ItemsData = itemsData;
            end
            % Reset the value since it may have been purged from the list
            if ismember(oldValue,src.ItemsData)
                src.Value = oldValue;
            else
                notify(obj,"ValueChanged");
            end
        end

        function makeNewFcn(obj,~,~)
            % ButtonPushedFcn for NewFcnButton
            if isequal(obj.FcnType,"local")
                % Get handle to current live script
                d = matlab.desktop.editor.getActive;
                % Append txt to the bottom of the live script and go this new fcn
                d.appendText(obj.NewFcnText);
                d.goToFunction(obj.NewFcnName);
                % Select new fcn from the dropdown
                obj.LocalValue = obj.NewFcnName;
            else
                % Create a new .m file with the template function
                matlab.desktop.editor.newDocument(obj.NewFcnText);
                % Note we cannot auto-select new file since we need user to
                % save and name the file first
            end
            notify(obj,"ValueChanged");
        end

        function validateFcnHandle(obj,src,event)
            val = src.Value;
            if isempty(val)
                if ~obj.AllowEmpty
                    % return to the previous value
                    src.Value = event.PreviousValue;
                    return
                end
            elseif ~isequal(val(1),'@')
                % add the at sign for the user
                src.Value = ['@' val];
            end
            notify(obj,"ValueChanged");
        end

        function browseForFile(obj,~,~)
            % BrowseButton clicked callback: behavior copied from Optimize
            % live task
            [file, path] = uigetfile({'*.m; *.mlx'},...
                string(message("MATLAB:dataui:fcnSelectorBrowseWindowTitle")),...
                [pwd, filesep]);

            % If a valid file was selected, extra handling
            if ~isequal(file, 0)
                % Set the component value
                [~, obj.BrowseValue, ~] = fileparts(file);
                % Add fcn folder to path
                addpath(path);
                notify(obj,"ValueChanged");
            end
        end

        function resetToDefault(obj)
            % Restores default values for controls
            obj.FcnType = "local";
            obj.BrowseValue = '';
            obj.HandleValue = obj.HandleDefault;
            obj.LocalValue = 'select variable';
        end
    end

    methods
        function val = get.FcnType(obj)
            val = obj.FcnTypeDropDown.Value;
        end

        function set.FcnType(obj,val)
            if ismember(val,obj.FcnTypeDropDown.ItemsData)
                obj.FcnTypeDropDown.Value = val;
            end
        end

        function val = get.LocalValue(obj)
            val = obj.LocalFcnDropDown.Value;
        end

        function set.LocalValue(obj,val)
            if isequal(val,'select variable')
                % Quick return for the default value since it is always
                % there. No need to check script and populate dd.
                obj.LocalFcnDropDown.Value = val;
                return
            end
            populateLocalFcnDD(obj);
            if ~ismember(val,obj.LocalFcnDropDown.ItemsData)
                % When setting while loading, script may not be active file
                % yet, so manually set the Items/ItemsData                
                obj.LocalFcnDropDown.Items = [obj.LocalFcnDropDown.Items cellstr(val)];
                obj.LocalFcnDropDown.ItemsData = [obj.LocalFcnDropDown.ItemsData cellstr(val)];                
            end
            obj.LocalFcnDropDown.Value = val;
        end

        function val = get.HandleValue(obj)
            val = obj.HandleEditField.Value;
        end

        function set.HandleValue(obj,val)
            obj.HandleEditField.Value = val;
        end

        function val = get.Enable(obj)
            val = obj.FcnTypeDropDown.Enable;
        end

        function set.Enable(obj,val)
            obj.FcnTypeDropDown.Enable = val;
            obj.LocalFcnDropDown.Enable = val;
            obj.NewFcnButton.Enable = val;
            obj.HandleEditField.Enable = val;
            obj.BrowseEditField.Enable = val;
            obj.BrowseButton.Enable = val;
        end

        function val = get.Tooltip(obj)
            val = obj.GridLayout.Tooltip;
        end

        function set.Tooltip(obj,val)
            obj.GridLayout.Tooltip = val;
        end

        function val = get.Value(obj)
            % Used primarily for script generation
            val = '';
            switch obj.FcnTypeDropDown.Value
                case "local"
                    if ~isequal(obj.LocalFcnDropDown.Value,"select variable")
                        val = ['@' obj.LocalFcnDropDown.Value];
                    end
                case "handle"
                    val = obj.HandleEditField.Value;
                case "file"
                    if ~isempty(obj.BrowseValue)
                        val = ['@' obj.BrowseValue];
                    end
            end
        end

        function val = get.State(obj)
            val = struct("FcnType",obj.FcnType,...
                "LocalValue",obj.LocalValue,...
                "HandleValue",obj.HandleValue);
            if obj.IncludeBrowse
                val.BrowseValue = obj.BrowseValue;
            end
        end

        function set.State(obj,val)
            obj.FcnType = val.FcnType;
            obj.LocalValue = val.LocalValue;
            obj.HandleValue = val.HandleValue;
            if obj.IncludeBrowse && isfield(val,'BrowseValue')
                obj.BrowseValue = val.BrowseValue;
            end
        end
    end
end