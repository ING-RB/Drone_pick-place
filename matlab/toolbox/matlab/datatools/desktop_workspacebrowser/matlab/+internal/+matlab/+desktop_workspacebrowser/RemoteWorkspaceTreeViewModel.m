classdef RemoteWorkspaceTreeViewModel < internal.matlab.variableeditor.peer.RemoteStructureTreeViewModel & internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase
    % RemoteWorkspaceTreeViewModel is the tree view model for workspacebrowser    
    
    % Copyright 2023 The MathWorks, Inc.

    properties(SetAccess='public', GetAccess='public', Dependent=false, Hidden=true)
        WorkspaceDataCache;
    end

    events
        PropertyChange;
    end

    properties(Access = private)
        % Save the evaluated value when changing the data.  This is used in
        % places where superclasses may try to do an evalin 'caller',
        % expecting caller to be the user's workspace.
        evaluatedSetValue;
    end

    methods
        function this = RemoteWorkspaceTreeViewModel(document, variable, viewID, UserContext)
            if nargin < 4
                UserContext = '';
            end
            this = this@internal.matlab.variableeditor.peer.RemoteStructureTreeViewModel(document, variable, ...
                            viewID, UserContext); 
            this@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(variable);       
        end

        function sendVariableEvent(this, type, Variables)
            this.sendVariableEvent@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(type, Variables);
        end

        % Gets the VariableName that will be used to index into the leaf
        % field of 'varName'. If the field's parent is a structArray or objectArray, 
        % index into the first element of the struct like 'parent(1).fieldName'
        function subVarName = getSubVarName(this, Name, varName)
            fieldVals = strsplit(varName, ".");
            if length(fieldVals) > 2
                data = this.getData();
                parentVal = getfield(data, fieldVals{1:end-1});
                % If we have struct whose child is a struct or object array (1xn
                % or nx1), then generate subVar to point to first entry of
                % the struct array.
                if this.checkExpandability(parentVal) && ~isscalar(parentVal)
                    varName = extractBefore(varName, ['.' fieldVals{end}]) + "(1)." + fieldVals{end};
                end
            end
            subVarName = varName;
        end

        % Handles event dispatches from client.
        % ed eventData with payload (struct('type','','originator','',srcLang:'CPP','data',[],target,[<ViewModel>])
        function varargout = handleEventFromClient(this, ~, ed)
            this.logDebug('PeerArrayView','handlePeerEvents','');
            varargout = {};
            if isfield(ed.data,'type')
                switch ed.data.type
                    case 'VariablesAdded'
                    case 'VariablesRemoved'
                    case 'VariablesChanged'
                    otherwise
                        this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteStructureViewModel([], ed);
                end
            end
        end

        % Overrides the getRenderedData function from the
        % StructureTreeViewModel and RemoteWorkspaceTreeViewModel.
        % In this implementation, we do not call getUpdatedDataForObjects because
        % the data returned from getRenderedData in StructureTreeViewModel does not
        % involve ObjectValueSummary objects, thus no conversion of these objects is needed.
        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            renderedData = [];
            renderedDims = [];
           
            if (startColumn > 0 && endColumn > 0)
                % The data returned from getRenderedData in
                % StructureTreeViewModel does not contain
                % ObjectValueSummary objects, so no conversion is required
                [data, ~, classValues, fieldColumns] = this.getRenderedData@internal.matlab.variableeditor.StructureTreeViewModel(...
                    startRow, endRow, startColumn, endColumn);
                [renderedData, ~] = this.renderData(data, classValues, fieldColumns, {}, ...
                    startRow, endRow, startColumn, endColumn);           
                renderedData = renderedData(:, startColumn:endColumn);
                renderedDims = size(renderedData);
            end
        end

        % Helper function to retrieve the data for the workspace
        % using the cache.
        % Can be enhanced by weak reference in the future
        function data = getData(this)
            if isempty(this.WorkspaceDataCache)
                % If the cache is empty, fetch the workspace data
                wsVarNames = evalin(this.DataModel.Workspace, this.DataModel.Name);
                [this.WorkspaceDataCache, ~, ~] = this.DataModel.getStructOfWSContents(wsVarNames);
            end
            data = this.WorkspaceDataCache;
        end  
    end

    methods(Access = protected)
     
        % Override from RemoteStructViewModel to provide
        % WorkspaceFieldSettings as WorkspaceBrowser has a separate
        % settings file.
        function fieldSettings = getFieldSettingsInstance(~)
            fieldSettings = internal.matlab.desktop_workspacebrowser.FieldColumns.WorkspaceFieldSettings.getInstance;           
        end

        % WSB does not have any server side plugins, do not initialize
        % widgetRegistry to save on startup.
        function initializePlugins(this)
        end
        
        function initFieldColumns(this, userContext)
            this.initFieldColumns@internal.matlab.variableeditor.peer.RemoteStructureViewModel(userContext);
            fieldColumn = this.findFieldByHeaderName("Name");
            fieldColumn.setHeaderTagName(getString(message('MATLAB:codetools:variableeditor:Name')));
            
            % Initialize Bytes Column to be added in additional to the
            % struct columns
            % TODO: Insert bytes col at position4, wire in to
            % insertFieldAt() API that will be added with column
            % re-ordering.
            settingsController = this.getSettingsController(userContext);
            visibleCols = internal.matlab.variableeditor.StructureViewModel.getVisibleColumns(settingsController);
            if ismember(visibleCols, 'Bytes')
                this.createBytesCol(settingsController);
            end       
        end

        function col = evaluateFieldCol(this, settingsController, colName)
            if strcmp(colName,'Bytes')
                col = this.createBytesCol(settingsController);
            else
                col = this.evaluateFieldCol@internal.matlab.variableeditor.peer.RemoteStructureViewModel(settingsController, colName);
            end
        end

        function bytesCol = createBytesCol(this, settingsController)
            bytesCol = this.createBytesCol@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(settingsController);
        end

        function result = evaluateClientSetData(this, ~, ~, ~)
            % Return the previously evaluated value, because evalin
            % 'caller' from the superclasses won't be correct
            result = this.evaluatedSetValue;
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModel';
        end
        
        function renameCmd = handleFieldNameEdit(this, data, row, column)
            renameCmd = this.handleFieldNameEdit@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(data, row, column);
        end
        
        function msg =  getErrorOnInvalidRename(this, rawData)
            msg = this.getErrorOnInvalidRename@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(rawData);
        end
        
        function b = didValuesChange(this, eValue, currentValue, row, column)            
            b = this.updateIfObjectValueSummary(currentValue, row, column);
            if ~b
                % If no update was necessary, proceed with the standard value change check
                b = this.didValuesChange@internal.matlab.variableeditor.peer.RemoteStructureViewModel(eValue, currentValue);
            end
        end
        
        % If rawData is of type ObjectValueSummary, return the DisplayValue
        % directly, else fall back for FormatDataUtil's formatting.
        function formattedData = getFormattedData(this, rawData)
            if (isa(rawData, 'internal.matlab.workspace.ObjectValueSummary'))
                formattedData = rawData.DisplayValue;
            else
                formattedData = this.getFormattedData@internal.matlab.variableeditor.peer.RemoteStructureViewModel(rawData);
            end            
        end

        % Overrides the handleDataChangedOnDataModel method to add additional
        % logic for handling changes in the data model. It checks if any of
        % the changed variables in the ExpansionList. If so, the viewport
        % rendering boundaries (StartRow, EndRow, StartColumn, EndColumn)
        % are cleared, prompting a full re-rendering of the viewport.
        function handleDataChangedOnDataModel(this, es, ed)
            % Update the cache whenever data change
            wsVarNames = evalin(this.DataModel.Workspace, this.DataModel.Name);
            [this.WorkspaceDataCache, ~, ~] = this.DataModel.getStructOfWSContents(wsVarNames);
 
            % Check if any of the changed variables are in the ExpansionList
            % If so, clear StartRow and EndRow to re-render the whole view port
            if ~isempty(ed.VarsChanged) && ~isempty(this.ExpansionList)
                % Convert the cell array ed.VarsChanged to a string array for easier
                % comparison with the string array this.ExpansionList.
                varsChangedStrArray = string(ed.VarsChanged);
 
                % Concatenate the workspace name, i.e. 'who', with
                % each of the variables in VarsChanged.
                % For example, if VarsChange contains 'a', and the
                % workspace name is 'who', then fullVarNames will
                % contain 'who.a' to match the format in the ExpansionList
                fullVarNames = this.DataModel.Name + "." + varsChangedStrArray;
                
                isExpanded = ismember(fullVarNames, this.ExpansionList);
                if any(isExpanded)
                    ed.StartRow = [];
                    ed.EndRow = [];
                    ed.StartColumn = [];
                    ed.EndColumn = [];
                end
            end
 
            % Call the superclass's handleDataChangedOnDataModel method
            handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteStructureTreeViewModel(this, es, ed);
        end
    end 

    methods(Static)
        function hName = getHeaderName(fcol)
            hName = getHeaderName@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(fcol);
        end
    end
end
