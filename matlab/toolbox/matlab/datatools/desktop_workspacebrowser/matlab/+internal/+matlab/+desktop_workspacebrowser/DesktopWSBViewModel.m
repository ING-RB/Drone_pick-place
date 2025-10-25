classdef DesktopWSBViewModel < internal.matlab.variableeditor.ViewModel ...
        & internal.matlab.variableeditor.BlockSelectionModel

    % ViewModel for the Desktop Workspace Browser

    % Copyright 2024-2025 The MathWorks, Inc.

    properties
        SelectedFields string
        userContext (1,1) string = "MOTW_Workspace";
    end

    properties(SetAccess={?internal.matlab.desktop_workspacebrowser.DesktopWSBManager})
        dispatchEventToClient function_handle = function_handle.empty;
    end

    events
        DataChange
        UserDataInteraction
        PropertyChange
    end

    properties(SetAccess={?matlab.unittest.TestCase, ?DesktopWSBViewModel})
        FieldColumnList containers.Map;
        VisibleFieldColumnList containers.Map;
    end
    
    methods
        function this = DesktopWSBViewModel(dataModel)
            this@internal.matlab.variableeditor.ViewModel(dataModel);
            this.updateFieldColumns;
        end

        function updateFieldColumns(this)
            this.FieldColumnList = containers.Map('KeyType', 'double', 'ValueType', 'any');
            this.VisibleFieldColumnList = containers.Map('KeyType', 'double', 'ValueType', 'any');

            s = settings;
            shownColumns = s.matlab.desktop.workspace.columns.ColumnsShown.ActiveValue;
            fieldColumsMap = internal.matlab.variableeditor.FieldColumns.StructFieldsList.FieldColumnsMap;
            fieldNames = fieldnames(fieldColumsMap);

            % Add in the Bytes column, which is specific to the WSB
            fieldNames = [fieldNames; 'Bytes'];
            fieldColumsMap.Bytes = "internal.matlab.desktop_workspacebrowser.FieldColumns.BytesCol";

            for i=1:length(fieldNames)
                name = string(fieldNames{i});
                className = fieldColumsMap.(name);
                try
                    instance = eval(className);
                    this.FieldColumnList(i) = instance;
                    if any(ismember(shownColumns, name))
                        this.VisibleFieldColumnList(i) = instance;
                        instance.Visible = true;
                    else
                        instance.Visible = false;
                    end
                catch e
                    internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBViewModel::updateFieldColumns", "Error: " + e.message);
                end
            end
        end

        % getRenderedData
        function varargout = getRenderedData(~, varargin)

        end

        % isSelectable
        function selectable = isSelectable(~)
            selectable = true;
        end

        % isEditable
        function editable = isEditable(~, ~)
            editable = true;
        end

        function varargout = getData(~, varargin)
            varargout{1} = struct;
        end

        function size = getSize(this)
            size = [0, 0];
            s = this.DataModel.Data;
            if ~isempty(s) && isstruct(s)
                fn = fieldnames(s);
                h = height(fn);
                s = settings;
                fcl = s.matlab.desktop.workspace.columns.ColumnsShown.ActiveValue;
                w = length(fcl);

                size = [h w];
            end
        end

        function size = getTabularDataSize(this)
            size = this.getSize();
        end
        
        function data = updateData(~, varargin)
            data = struct;
        end

        function varargout = setData(~, varargin)
            varargout{1} = '';
        end

        function varargout = getFormattedSelection(~)
            varargout{1} = "x";
        end

        function selectedFields = getSelectedFields(this)
            selectedFields = this.SelectedFields;
        end

        function val = getProperty(~, ~)
            val = [];
        end

        function val = getTableModelProperty(~, prop)
            val = [];
            if prop == "editable"
                val = true;
            end
        end

        function field = findFieldByHeaderName(this, headerName)
           l = this.FieldColumnList.Count;
           field = [];
           for i=1:l
               f = this.FieldColumnList(i);
               if strcmp(f.HeaderName, headerName)
                   field = f;
                   return;
               end
           end
        end

        function setColumnVisible(~, fieldColumnName, isVisible)
            s = settings;
            currentVisibleColumns = s.matlab.desktop.workspace.columns.ColumnsShown.ActiveValue;

            if isVisible
                currentVisibleColumns = unique([currentVisibleColumns, fieldColumnName], "stable");
            else
                currentVisibleColumns(string(currentVisibleColumns) == string(fieldColumnName)) = [];
            end

            s.matlab.desktop.workspace.columns.ColumnsShown.PersonalValue = currentVisibleColumns;
        end
    end
end
