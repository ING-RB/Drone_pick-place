classdef FieldVariableColumn < handle
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class Defines a field column displayed within a scalar struct
    % view.

    % Copyright 2020-2023 The MathWorks, Inc.
    properties
        Sortable logical;     
        Editable logical;
    end
    
    properties(Dependent=true)
        Visible logical;
        ColumnWidth double;
        ColumnIndex double;
    end
    
    properties(SetAccess = 'protected')
        HeaderName string;
        TagName;       
        DataAttributes;
        SortAscending logical;
        CustomColumn logical = false;
    end
    
    properties(Hidden)
        SettingsController internal.matlab.variableeditor.FieldColumns.StructFieldSettings;
    end

    properties(Constant, Hidden)
        UNDEFINED_DISPLAY_VAL = '-';
    end
    
    % These internal properties are returned as defaults in the absence of
    % a SettingsController
    properties(Hidden, SetAccess = 'protected')
        Visible_I logical;
        ColumnWidth_I double = 75;
        ColumnIndex_I double;
    end
    
    methods
        function this = FieldVariableColumn(props)
            if nargin > 0 && isa(props, 'struct')
                fnames = fieldnames(props);
                for i=1:length(fnames)
                   key = fnames{i};
                   if isprop(this, key)
                       this.(key) = props.(key);
                   end
                end
            end
        end
        
        function headerName = getHeaderName(this)
            headerName = this.HeaderName;
        end       
        
        function tagName = getHeaderTagName(this)
            tagName = this.TagName;
        end
        
        function setHeaderTagName(this, tagName)
            if ~isempty(tagName)
                this.TagName = tagName;
            end
        end  
        
        function dataAttributes = getDataAttributes(this)
            dataAttributes = this.DataAttributes;
        end
        
        function setColumnIndex(this, columnIndex)
            arguments
                this (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
                columnIndex (1,1) {mustBeNumeric}
            end
            this.ColumnIndex = columnIndex;
        end
        
        % Sets value of SortAscending on the FieldVariableColumn.
        function setSortAscending(this, val)
            arguments
                this (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
                val (1,1) logical
            end
            this.SortAscending = val;
        end
        
        function colIndex = getColumnIndex(this)
            colIndex = this.ColumnIndex;
        end
        
        function setDataAttributes(this, dataAttributes)
            this.DataAttributes = dataAttributes;
        end

        % Sets ColumnWidth in fieldColumn as well as SettingsController
        % Happens when Columns are resized from their default widths.
        function set.ColumnWidth(this, ColumnWidth)
            arguments
                this (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
                ColumnWidth (1,1) {mustBeNumeric}
            end     
             if ~isempty(this.SettingsController)
                this.SettingsController.setColumnWidth(this.ColumnIndex, ColumnWidth);
             else
                this.ColumnWidth_I = ColumnWidth; 
            end
        end
        
        % Gets ColumnWidth of the column
        function colWidth = get.ColumnWidth(this)
            if ~isempty(this.SettingsController)
                colWidth = this.SettingsController.getColumnWidth(this.ColumnIndex);
            else 
                colWidth = this.ColumnWidth_I;
            end
        end
        
        % Sets visibility in fieldColumn as well as SettingsController
        % Happens when columns are shown/hidden via the header menu.
        function set.Visible(this, isVisible)
            arguments
                this (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
                isVisible (1,1) {mustBeNumericOrLogical}
            end     
             if ~isempty(this.SettingsController)
                this.SettingsController.setColumnVisibility(this.HeaderName, isVisible);
             else
                 this.Visible_I = isVisible;
            end
        end
        
        % Returns true if the fieldColumn is shown and false otherwise.
        function isVisible = get.Visible(this)
            if ~isempty(this.SettingsController)
                isVisible = this.SettingsController.getColumnVisibility(this.HeaderName);
            else
                isVisible = this.Visible_I;
            end
        end
        
        % Sets ColumnIndex in fieldColumn as well as SettingsController
        % (Happens when columns are re-ordered)
        function set.ColumnIndex(this, columnOrder)
            arguments
                this (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
                columnOrder (1,1) {mustBeNumeric}
            end     
             if ~isempty(this.SettingsController)
                this.SettingsController.setColumnOrder(this.HeaderName, columnOrder);
             else
                 this.ColumnIndex_I = columnOrder;
            end
        end
        
        % Gets ColumnIndex (Order in which the column is displayed)
        function columnIndex = get.ColumnIndex(this)
            if ~isempty(this.SettingsController)
                columnIndex = this.SettingsController.getColumnOrder(this.HeaderName);
            else
                columnIndex = this.ColumnIndex_I;
            end
        end
    end
    
     methods(Abstract)
        getSortedIndices(this);        
    end
end