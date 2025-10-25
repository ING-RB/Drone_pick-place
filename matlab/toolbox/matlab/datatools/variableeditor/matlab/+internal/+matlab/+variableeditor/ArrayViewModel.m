classdef ArrayViewModel < internal.matlab.variableeditor.ViewModel & ...
                          internal.matlab.variableeditor.BlockSelectionModel & ...                          
                          internal.matlab.datatoolsservices.FormatDataUtils & ...
                          internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore & ...
                          internal.matlab.datatoolsservices.data.TabularDataStore
    %ARRAYVIEWMODEL
    %   Abstract Array View Model

    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties
        userContext char = ' ';
        DisplayFormatProvider internal.matlab.variableeditor.NumberDisplayFormatProvider;
    end
    
    properties(Hidden)
        % Format as a single cell for getting display value alone.
        FormatAsSingleCell logical = false;
    end
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = ArrayViewModel(dataModel, viewID, userContext, displayFormat)
            arguments
                dataModel
                viewID = ''
                userContext = ''
                displayFormat char = ''
            end
            this@internal.matlab.variableeditor.ViewModel(dataModel);
            if ~isempty(viewID)
                this.viewID = viewID;
            end
            if ~isempty(userContext)
                this.userContext = userContext;
                dataModel.userContext = userContext;
            end
            this.DisplayFormatProvider = internal.matlab.variableeditor.NumberDisplayFormatProvider(this.userContext, displayFormat);
        end
        
        % isSelectable
        function selectable = isSelectable(~)
            selectable = true;
        end
        
        % isEditable
        function editable = isEditable(varargin)
            editable = true;
        end

        % getData
        function varargout = getData(this,varargin)
            varargout{1} = this.DataModel.getData(varargin{:});
        end
        
        function varargout = setTabularDataValue(this, row, column, value, errormsg)
            arguments
                this
                row
                column
                value
                errormsg = ''
            end
            if ~isempty(errormsg)
                varargout{1} = this.setData(value, row, column, errormsg);
            else
                varargout{1} = this.setData(value, row, column);
            end
        end

        % setData
        function varargout = setData(this,varargin)
            varargout{1} = this.DataModel.setData(varargin{:});
        end
        
        function s = getTabularDataSize(this)            
            s = this.getSize();            
        end

        % getSize
        function s = getSize(this)
            s=this.DataModel.getSize();
        end

        % updateData
        function data = updateData(this, varargin)
            data = this.DataModel.updateData(varargin{:});
        end
        
        function [data, dims] = getTabularDataRange(this, startRow, endRow, startColumn, endColumn)
           [data,dims] = this.getRenderedData(startRow, endRow, startColumn, endColumn);
        end
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
           data = this.getData(startRow,endRow,startColumn,endColumn);
           [renderedData, renderedDims] = internal.matlab.variableeditor.ArrayViewModel.getParsedArrayData(data); 
        end

        % getRenderedData returns a cellstr for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
           [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
        
         % public API for actions to update model properties. NOTE: Move
         % these as utilities for actions at some point.
        function updateRowMetaData(this)
           this.refreshAllMetaData('RowMetaDataChanged');
        end
        
        function updateColumnMetaData(this)           
           this.refreshAllMetaData('ColumnMetaDataChanged');           
        end

        function updateCellMetaData(this)
            this.refreshAllMetaData('CellMetaDataChanged');
           end
        
    end
    
    methods(Access='private')
        function refreshAllMetaData(this, metadataType)
           s = this.getSize();
           md = this.MetaDataStore;
           eventdata = internal.matlab.datatoolsservices.data.ModelChangeEventData;
           eventdata.Row = 1:s(1,1);
           eventdata.Column = 1:s(1,2); 
           md.notify(metadataType, eventdata); 
        end
    end
   
    methods(Static)
        function [renderedData, renderedDims] = getParsedArrayData(data)
            vals = cell(size(data,2),1);
            for column=1:size(data,2)
                r=evalc('disp(data(:,column))');
                if ~isempty(r)
                    textformat = ['%s', '%*[\n]'];
                    vals{column}=strtrim(textscan(r,textformat,'Delimiter',''));
                end
            end
            renderedData=[vals{:}];

            if ~isempty(renderedData)
                renderedData=[renderedData{:}];
            end

            renderedDims = size(renderedData);
        end
        
        % Static fn that allows users to register a context with a boolean
        % that tells whether SettingsController is valid for the current
        % view or not.
        % For E.g We restore ColumnWidths/Order etc for MOTW views but
        % other consumers like UIVariableEditor have transient views that
        % must not be affected by settings.
        function useSettingForContext(context, useSettings)
            arguments
                context string
                useSettings logical
            end
            regnMap = internal.matlab.variableeditor.ArrayViewModel.getSettingRegistrationMap();
            regnMap(context) = useSettings;
        end
        
        % Static fn that creates a SettingRegistration Map first time when
        % called. This Map Keeps track of contexts that are registered and
        % flags to determine whether a FieldSettings Controller must be
        % used for the FieldColumns.
        function regnMap = getSettingRegistrationMap()
            mlock;
            persistent SettingsRegistrationMap;
            if isempty(SettingsRegistrationMap)
                SettingsRegistrationMap = containers.Map();
            end
            regnMap = SettingsRegistrationMap;
        end

        function useSettingForContext = shouldUseSettingsForContext(userContext)
            settingsRegnMap = internal.matlab.variableeditor.ArrayViewModel.getSettingRegistrationMap();
            useSettingForContext = (~isempty(userContext) && isKey(settingsRegnMap, userContext) && settingsRegnMap(userContext));
        end
    end
end
