classdef WebMWTableController < matlab.ui.internal.componentframework.WebComponentController & ...
                            matlab.ui.internal.controller.uitable.UITableCellEditMixin
    %WEBTABLECONTROLLER Web-based controller for UITable.
    
    %   Copyright 2014-2023 The MathWorks, Inc.
    
    properties(Access = 'protected')
        PositionBehavior
        LayoutBehavior
        hasContextMenuBehavior
        CellEditingHandler
        ServerReady = false;
        HasRowHeader = false;
        HasRowHeaderNumber = false;
        HasColumnName = true;
        TableView;   % Interface for controller to talk its view implementation.
        DEFAULT_COLUMN_WIDTH = 'auto';
    end
    
    properties(Access = 'public')
        StylesManager;
        DataRenderedInView = false;
        LazyLoadingStatusRequestCompleted = false;
    end
    properties(Access = 'private')
        
        % Handles text related functionality
        TextFormatterManager;
        LazyLoadingEnabled = false;
        ClientTableCreationStarted = false;
    end
    
    methods
        function className = getViewModelType(obj, ~)
            if obj.Model.isInAppBuildingFigure()
                className = 'matlab.ui.control.Table';
            else
                className = 'matlab.ui.control.LegacyTable';
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebMWTableController( model, varargin )
            
            % Super constructor
            obj = obj@matlab.ui.internal.componentframework.WebComponentController( model, varargin{:});
            obj@matlab.ui.internal.controller.uitable.UITableCellEditMixin(model);
            obj.PositionBehavior = matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn(obj.PropertyManagementService);
            obj.LayoutBehavior = matlab.ui.internal.componentframework.services.optional.LayoutBehaviorAddOn(obj.PropertyManagementService);
            obj.hasContextMenuBehavior = matlab.ui.internal.componentframework.services.optional.HasContextMenuBehaviorAddOn(obj.PropertyManagementService);
            
            % set mw-table data store and view.
            obj.TableView = matlab.ui.internal.controller.uitable.MWTableDataStore(obj);
            obj.StylesManager = matlab.ui.internal.controller.uitable.StylesManager(model);
            
            % Handles text related functionality
            obj.TextFormatterManager = matlab.ui.internal.controller.uitable.viewservices.TextFormatterManager(model);
            
            obj.ServerReady = true;
        end

        function pvPairs = getPropertiesForViewDuringConstruction (obj, ~, ~)
            % Create property/value (PV) pairs
            except = ["FontSize"];
            pvPairs = obj.PropertyManagementService.defineModelPvPairs(obj.Model, except);
        end
        
        function LazyLoadingEnabled = getLazyLoadingStatus(obj)
            if(~obj.ClientTableCreationStarted)
                viewModelObject = obj.ViewModel;
                eventData.Name = 'LazyLoadingStatusRequested';
                viewModelObject.dispatchEvent('peerEvent', eventData, viewModelObject.Id);
                waitfor(obj, 'LazyLoadingStatusRequestCompleted', true);
                LazyLoadingEnabled = obj.LazyLoadingEnabled;
                obj.LazyLoadingStatusRequestCompleted = false;
            else
                LazyLoadingEnabled = false;
            end
        end
        
        function fireServerReadyEvent(obj)
            % tell client side 'ServerReady' with Channel and PeerNodeID
            % for DataTools DataStore connection.
            if obj.ServerReady
                metadataDefaults = obj.TableView.getMetadataDefaults();
                [channel] = obj.TableView.getViewInfo();
                payload = {'Channel', channel, 'MetadataDefaults', metadataDefaults};

                func = @() obj.EventHandlingService.dispatchEvent('ServerReady', payload);
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
            end
        end

        function delete(obj)
            % DELETE - Mark the StyleConfigurations as dirty if the model
            % still exists. This occurs when the controller is destroyed
            % and recreated
            if isvalid(obj.Model)
                obj.StylesManager.markStylesDirty();
            end
        end
    end

    methods (Access = protected)
        function postSet(obj, property )
            % POSTSET - React to properties handled by setProperty which do
            % not require interaction with the peernode.
            obj.setProperties(property);
        end

        function updateFullView_Post (obj)
            % Specifically populate LayoutConstraints property before table server creation. (g1962747)
            % The current architecture of client GridController needs the
            % information of LayoutConstraints for its child added event.
            % (_handleChildAdded in GridController.js)
            % It requires the server to update LayoutConstraints property
            % right after peer node creation.
            obj.triggerUpdateOnDependentViewProperty("LayoutConstraints");
            
            % For applicable view properties which participate in dependencies with
            % model properties, trigger the customized update methods.
            exceptList = string.empty;
            if isempty(obj.Model.Selection)
                exceptList = "Selection";
            end
            obj.triggerUpdatesOnDependentViewProperties(exceptList);

        end
    end

    methods (Access = private)
        function setProperties(obj, propertyNames)
            import appdesservices.internal.util.ismemberForStringArrays;

            % Order properties by frequency of use
            propertyNames = string(propertyNames);

            checkFor = ["Data", "ColumnEditable", "ColumnSortable", "ColumnFormat",...
                        "ColumnWidth", "ColumnName", "RowName", "BackgroundColor", "RowStriping",... 
                        "ForegroundColor", "FontWeight", "FontAngle", "FontName", "FontSize", "StyleConfigurationStorage"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);

            if isPresent(1)
                    obj.updateData();
            end
            if isPresent(2)
                obj.updateColumnEditable(); % View property
            end
            if isPresent(3)
                obj.updateColumnSortable();
            end
            if isPresent(4)
                obj.updateColumnFormat();
            end
            if isPresent(5)
                obj.updateColumnWidth();
            end
            if isPresent(6)
                obj.updateColumnName();
            end
            if isPresent(7)
                obj.updateRowName();
            end
            if any(isPresent(8:9))
                obj.updateBackgroundColor();
            end
            if any(isPresent(10:14))
                obj.updateTableStyle();
            end
            if isPresent(15)
                obj.updateStyleConfigurationStorage();
            end
        end
    end
    methods
        
        function updateData(obj)
            
            % don't save data in PeerNode
            newData = '';
            
            % Update text formatter manager if necessary
            obj.TextFormatterManager.handleDataChanged(obj.Model);
            
            % Store size of data from last time dataStore was updated
            originalDataStoreDataSize = obj.TableView.getDataStoreSourceDataSize();
             
            % If there is a cell edit, notify datastore to update mw-table
            % view of the single cell
            if obj.IsEditing
                row = obj.EditingIndex(1);
                column = obj.EditingIndex(2);

                % Update view for single cell in table
                obj.updateSingleCellData(row, column);
            else
                % Update view for entire table
                obj.TableView.updateViewData();
                
                % Tell client the data has changed when ColumnSortable is specified 
                % in order to reset sort indicator
                if any(obj.Model.ColumnSortable)
                    func = @() obj.EventHandlingService.dispatchEvent('ResetSortIndicator');
                    matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
                end
            end
            
            dataSize = size(obj.getSourceData());
                        
            % If number of rows has changed, trigger update in properties
            if originalDataStoreDataSize(1) ~= dataSize(1)
                updateBackgroundColor(obj);
            end
            
            % Update row data when switching back and forth from empty data
            % to non empty data.
            if any(originalDataStoreDataSize == 0) || any(dataSize == 0)
                obj.updateRowHeaderColumn();
            end
            
            % If number of columns has changed, trigger update in
            % properties.  This will allow the datastore to forward the
            % appropriate metadata for new columns or clear metadata for
            % excess columns.
            if originalDataStoreDataSize(2) ~= dataSize(2)
                               
                updateColumnName(obj);
                updateColumnWidth(obj);
                updateColumnFormat(obj);
            end
            
            % Editablity can be affected by the source data
            if originalDataStoreDataSize(2) ~= dataSize(2) || istable(obj.Model.Data)
                updateColumnEditable(obj);
            end
            % Sortability can be affected by the source data
            if originalDataStoreDataSize(2) ~= dataSize(2) || istable(obj.Model.Data) || iscell(obj.Model.Data)
                updateColumnSortable(obj);
            end
            
            if ~isequal(originalDataStoreDataSize, dataSize)
                % update data size to peer node for table creation.
                obj.EventHandlingService.setPropertyAndCommit('DataSize', dataSize);
            end
            
        end     

        function newSingleCellData = updateSingleCellData(obj, sourceRow, sourceColumn)
            newSingleCellData = '';
            
            % Update view for single cell in table
            displayCol = getDisplayColumnFromSourceColumn(obj, sourceColumn);
            displayRow = obj.getDisplayRowFromSourceRow(sourceRow);
            obj.TableView.updateSingleViewData(displayRow, displayCol, sourceRow, sourceColumn);
        end
        
        function updateColumnEditable(obj)
            editable = obj.Model.ColumnEditable;
            data = getSourceData(obj);
            dataCol = size(data, 2);

            if isempty(editable) || isequal(editable,false)
                % Mark all columns to be non-editable.
                viewEditable = false(1, dataCol);
            elseif isequal(editable, true)
                % Mark all columns to be editable.
                viewEditable = true(1, dataCol);
            else
                % Create a 1xn viewEditable array of falses
                viewEditable = false(1, dataCol);

                % Prevent the array from ever being larger than
                % the number of columns in the data
                numCol = min(length(editable), dataCol);
                viewEditable(1:numCol) = editable(1:numCol);
            end

            % If a column is set to editable, but the datatype is
            % non-editable, throw a warning.
            showWarning = false;
            for idx = 1:length(viewEditable)
                % If column is set to editable for non-editable data types.
                if viewEditable(idx) && ~obj.isEditableDataType(data,idx)
                    showWarning = true;
                elseif viewEditable(idx) && istable(data) && isempty(data{:,idx})
                    % If column is homogenous non-cell array of empty values,
                    % mark viewEditable false at this idx to prevent editing
                    % g2034289 - Do not trigger the warning for this edge
                    % case because the data type is valid, but the size of
                    % the homogenous array of empty values makes the
                    % underlying data non-editable in MATLAB
                    viewEditable(idx) = false;
                end
            end

            % Show the warning message based on the flag
            if showWarning
                w = warning('backtrace', 'off');
                warning(message('MATLAB:uitable:NonEditableDataTypes'));
                warning(w);
            end
                    
            % Notifies the datastore to set column editable 
            obj.TableView.setViewColumnEditable(viewEditable);
            newColumnEditable = '';
        end
        
        function newColumnSortable = updateColumnSortable(obj)
            % Notifies the datastore to set column sortable
            
            obj.TableView.setViewColumnSortable(obj.Model.ColumnSortable);
            newColumnSortable = '';
        end
        
        function updateColumnFormat(obj)

            % Update text formatter manager if necessary
            obj.TextFormatterManager.handleColumnFormatChanged(obj.Model);
            
            % Create a 1xn empty ColumnFormat
            dataCol = size(getSourceData(obj), 2);
            viewColumnFormat = cell(1, dataCol);

            % Prevent the ColumnFormat array from ever being larger than
            % the number of columns in the data
            numCol = min(dataCol, numel(obj.Model.ColumnFormat));

            % Set customized ColumnFormat
            viewColumnFormat(1:numCol) = obj.Model.ColumnFormat(1:numCol);

            % If not a cell edit, set to the view
            if ~obj.IsEditing
                obj.TableView.setViewColumnFormat(viewColumnFormat);
            end
            
        end
        
        function updateColumnWidth(obj)
            
            widths = obj.Model.ColumnWidth;
            dataCol = size(getSourceData(obj), 2);
            numCol = dataCol;
            
            if ischar(widths)
                             
                % Will be 'auto', 'fit', '1x'...'Nx'
                viewWidths = repmat({widths}, 1, numCol);
            else
                numCol = min(dataCol, numel(widths));
                
                viewWidths = repmat({obj.DEFAULT_COLUMN_WIDTH}, 1, dataCol);
                viewWidths(1:numCol) = obj.Model.ColumnWidth(1:numCol);
                
                % to replace 'auto' with default widths for now.
                autoWidths = strcmp(viewWidths, 'auto');
                if any(autoWidths)
                    viewWidths(autoWidths) = {obj.DEFAULT_COLUMN_WIDTH};
                end
            end
            
            % set to the view.
            obj.TableView.setViewColumnWidth(viewWidths);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateColumnName
        %
        %  Description: Custome method to set ColumnName.
        %
        %  Inputs :     obj
        %  Outputs:     empty string-> as not need to set on the Web Table peernode
        %               as handled by the variable editor peernode.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function updateColumnName(obj)
            
            sourceColumnName = obj.Model.ColumnName;

            % Show column names
            if isequal(sourceColumnName, 'numbered')
                col = size(getSourceData(obj), 2);
                viewColumnNames = num2cell(1:col);      
            elseif ischar(sourceColumnName)
                viewColumnNames = cellstr(sourceColumnName);
            else                 
                viewColumnNames = sourceColumnName;
            end
            
            % replace '|' with newline for split multiple line head.
            viewColumnNames = cellfun( ...
                @(x)replacePipeWithNewline(obj, x), viewColumnNames, 'UniformOutput', false);
            
            
            % set names to the view.
            obj.TableView.setViewColumnName(reshape(viewColumnNames, 1, []));
            
            % Update the header visibility in view
            obj.updateColumnHeaderVisibility();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateRowName
        %
        %  Description: Custome method to set RowName.
        %
        %  Inputs :     obj
        %  Outputs:     empty string-> as not need to set on the Web Table peernode
        %               as handled by the variable editor peernode.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function updateRowName(obj)
            
            % If not a cell edit
            if ~obj.IsEditing
                % notify the view that row name is changed.
                % This must be called before re-creating the table as seen
                % in g1897962
                obj.TableView.clearRowMetaData(1:size(obj.Model.Data,1)); 

                % Re-create the mw-table if needed to show/hide the row
                % header column
                obj.updateRowHeaderColumn();
            end
        end
        
        function updateBackgroundColor(obj)

            % If not a cell edit
            if ~obj.IsEditing
                obj.TableView.clearRowMetaData(1:size(obj.Model.Data,1));
            end
        end
        
        function newRearrangeable = updateColumnRearrangeable(obj)
            newRearrangeable = logical(obj.Model.ColumnRearrangeable);
            obj.TableView.setViewColumnRearrangeable(newRearrangeable);
        end

        function newFontSize = updateFontSize(obj)
            % View property with dependency
            newFontSize = obj.Model.FontSize;
            try
                value = struct('FontSize', obj.Model.FontSize, 'FontUnits', obj.Model.FontUnits);
                newFontSize = value;
            catch e %#ok<NASGU>

            end
        end
        
        function newStyle = updateStyleConfigurationStorage(obj)
            newStyle = '';
            obj.StylesManager.handleStylesConfigurationChanged(obj);
        end
        
        % convert model selection indices to view indices.
        function newSelection = updateSelection(obj)
            % convert to view indices.
            selection = obj.TableView.convertToViewIndex(obj.Model.Selection, obj.Model.SelectionType);
            % convert selection indices to 0-based for JS client.
            selection = selection-1;

            % sort selection for optimization by JS client
            % Column first selection used for 'cell' SelectionType
            newSelection = struct('Selection', [], 'Identifier', matlab.lang.internal.uuid);
            if ~isempty(selection)
                if strcmp(obj.Model.SelectionType, 'cell')
                    newSelection.Selection = sortrows(selection,[2 1]);
                else
                    newSelection.Selection = sort(selection);
                end
            end
        end

        % Short-term solution to update Selection property when
        % SelectionType proerty changes.
        % @TODO need to refactor SelectionType data type.
        function newSelectionType = updateSelectionType(obj)
            if obj.Model.Multiselect
               newSelectionType = obj.Model.SelectionType;
            else 
               newSelectionType = ['single ' obj.Model.SelectionType];
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateFontName
        %
        %  Description: Custom method to set newFontName. Handles
        %  fixedwidth font
        %
        %  Outputs:     newFontName, fontName ready for the view
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newFontName = updateFontName( obj )
            newFontName = matlab.ui.internal.FontUtils.getFontForView(obj.Model.FontName);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updatePosition
        %
        %  Description: Method invoked when table position changes.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newPosValue = updatePosition(obj)
            newPosValue = obj.PositionBehavior.updatePosition(obj.Model);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateLayoutConstraints
        %
        %  Description: Method invoked when panel Layout Constraints change.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function constraintsStruct = updateLayoutConstraints(obj)
            constraintsStruct = obj.LayoutBehavior.updateLayout(obj.Model.Layout);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateContextMenuID
        %
        %  Description: Method invoked when table UIContextMenu property changes.  
        %
        %  Inputs :     None.
        %  Outputs:     
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newContextMenuID = updateContextMenuID( obj )
            newContextMenuID = obj.hasContextMenuBehavior.updateContextMenuID(obj.Model.UIContextMenu);
        end

        function newInteractionInformation = addComponentSpecificInteractionInformation(obj, interactionInformation, eventdata)
            % ADDCOMPONENTSPECIFICINTERACTIONINFORMATION -  Add any
            % InteractionInformation that is specific to this component.
            newInteractionInformation = obj.constructRowAndColumnInteractionInformation(eventdata, interactionInformation);
        end

        function interactionObject = constructInteractionObject(obj, interactionInformation)
            % CONSTRUCTINTERACTIONOBJECT - Construct the object to be used
            % with InteractionInformation.
            interactionObject = matlab.ui.eventdata.TableInteraction(interactionInformation);
        end
        
        % Method to configure whether a cell double click will suppress the editing mode. 
        function doubleClickedEditing = updateEnableDoubleClickedEditing(obj)
            if isempty(obj.Model.CellDoubleClickedFcn) 
                % default enable
                doubleClickedEditing = true;
            else
                % disable editing on cell double click
                % user has custom callback for cell double click.
                doubleClickedEditing = false;
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      bringToFocus
        %
        %  Description: Requests that the UITable be brought to focus
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function bringToFocus(obj)
            func = @() obj.EventHandlingService.dispatchEvent('FocusComponent');
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
        end
    
    end
    
    methods( Access = 'protected')
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      postAdd
        %
        %  Description: Custom method for controllers which gets invoked after the
        %               addition of the web component into the view hierarchy.
        %
        %  Inputs :     None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function postAdd( obj )
            
           % Manually process all properties that are not dependencies and
           % not peer node properties
            propsToHandleOnConstruction = {'Data', 'ColumnEditable', 'ColumnSortable', 'ColumnName', 'RowName', 'ColumnFormat', ...
                'BackgroundColor', 'RowStriping', 'ForegroundColor', 'FontAngle', 'FontName', ...
                'FontSize', 'FontWeight', 'ColumnWidth', 'StyleConfigurationStorage'};
            
            obj.setProperties(propsToHandleOnConstruction);

            % Attach a listener for events
            obj.EventHandlingService.attachEventListener( @obj.handleEvent );
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, obj is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based user interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.componentframework.WebComponentController(obj);
            % Add model properties concerning view specific to the table, 
            
            obj.PropertyManagementService.defineViewProperty( "Visible" );
            obj.PropertyManagementService.defineViewProperty( "Enable" );
            obj.PropertyManagementService.defineViewProperty( "Tooltip" );
            obj.PropertyManagementService.defineViewProperty( "Selection" );
            obj.PropertyManagementService.defineViewProperty( "RowScrollData" );
            obj.PropertyManagementService.defineViewProperty( "ColumnScrollData" );
            
            % Properties needs mapping/updates before updating to view
            obj.PropertyManagementService.defineViewProperty( "ColumnRearrangeable" );
            obj.PropertyManagementService.defineViewProperty( "FontSize" );
            obj.PropertyManagementService.defineViewProperty( "FontUnits" );
            obj.PropertyManagementService.defineViewProperty( "SelectionType" );
            obj.PropertyManagementService.defineViewProperty( "Multiselect" );
            obj.PropertyManagementService.defineViewProperty( "CellDoubleClickedFcn" );
            obj.PropertyManagementService.defineViewProperty( "FontName" );
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      definePropertyDependencies
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, obj is the method the "Controller"
        %               layer uses to establish property dependencies between
        %               a property (or set of properties) defined by the "Model"
        %               layer and dependent "View" layer property.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependencies( obj )

            % Need to recalculate 'auto' column width with new column names.
            obj.PropertyManagementService.definePropertyDependency("FontUnits", "FontSize");
            obj.PropertyManagementService.definePropertyDependency("Multiselect", "SelectionType");
            obj.PropertyManagementService.definePropertyDependency("CellDoubleClickedFcn","EnableDoubleClickedEditing");
            obj.PropertyManagementService.definePropertyDependency("RearrangeableColumns", "ColumnRearrangeable");
            definePropertyDependencies@matlab.ui.internal.componentframework.WebComponentController(obj);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineRequireUpdateProperties
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property which needs updates
        %               before updating them to view.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineRequireUpdateProperties( obj )
            obj.PropertyManagementService.defineRequireUpdateProperty('FontSize');
            obj.PropertyManagementService.defineRequireUpdateProperty('SelectionType');
            obj.PropertyManagementService.defineRequireUpdateProperty('Selection');
            obj.PropertyManagementService.defineRequireUpdateProperty('FontName');
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      handleEvent
        %
        %  Description: Custom handler for events.
        %
        %  Inputs :     event -> Event payload.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )
            % Handle events
            if( obj.EventHandlingService.isClientEvent( event ) )
                
                eventStructure = obj.EventHandlingService.getEventStructure( event );
                
                % handle Position events
                positionHandled = obj.PositionBehavior.handleClientPositionEvent( src, eventStructure, obj.Model );
                contextMenuEventHandled = obj.hasContextMenuBehavior.handleEvent(obj, obj.Model, src, eventStructure);
                if (~positionHandled && ~contextMenuEventHandled)
                  % handle other events
                  switch (eventStructure.Name)
                      case 'UpdateLazyLoadingState'
                          % Used to notify lazy loading status for table
                          % if table lazy loaded then getframe or print should not wait
                          obj.LazyLoadingEnabled = event.Data.LazyLoadSelfEnabled;
                          obj.LazyLoadingStatusRequestCompleted = true;
                      case 'CreateClientTable'
                          % Client is asking server to create client view 
                          % it may happen during initialization or client
                          % refresh (g1497011)
                          obj.fireServerReadyEvent();
                          obj.ClientTableCreationStarted = true;

                      case 'ColumnSorted'
                          obj.handleSortingFromView(eventStructure);
                          
                      case 'SelectionChanged'
                          indices = [];
                          displayIndices = [];
                          % Loop through the ranges. Ignore the "Name"
                          % field.
                          fieldNames = fieldnames(eventStructure);
                          filteredFieldNames = fieldNames(~strcmp(fieldNames, 'Name'));
                          for i = 1:numel(filteredFieldNames)

                              % Get data for 'range1', 'range2', etc.
                              rangeList = eventStructure.("range" + i);
                          
                              % Convert to MATLAB indexing
                              startRow = rangeList.startRow + 1;
                              endRow = rangeList.endRow + 1;
                              startColumn = rangeList.startColumn + 1;
                              endColumn = rangeList.endColumn + 1;

                              % When a ColumnHeader is selected, eventStructure
                              % reports endRow of Infinity, which becomes [] in
                              % MATLAB. Set endRow to the last row in the table
                              if isempty(endRow)
                                  endRow = size(obj.Model.Data,1);
                              end

                              % Similarly, when a RowHeader is selected, set
                              % endColumn to the last row in the table
                              if isempty(endColumn)
                                  endColumn = size(getSourceData(obj),2);
                              end

                              % Use displayIndices to find the indices
                              % Given row and column ranges, construct
                              % continous cells between them
                              [rangeIndices, rangeDisplayIndices] = obj.constructSelectedIndices(startRow, endRow, startColumn, endColumn);

                              % Add to the final indices arrays
                              indices = [indices; rangeIndices];
                              displayIndices = [displayIndices; rangeDisplayIndices];
                          end
                          previousSelection = obj.Model.Selection;
                          previousDisplaySelection = obj.getDisplaySelection(previousSelection);
                          
                          selection = obj.getSelectionFromView(indices);
                          displaySelection = obj.getDisplaySelection(selection);

                          % update client SelectionValue. This needs to be
                          % done before firing Callback to avoid possible timing
                          % issues in cases where Callback updates Selection.
                          obj.EventHandlingService.setPropertyAndCommit('SelectionValue', obj.convertToZeroBasedIndex(displaySelection));
                          
                          % Set Selection property in Model and fire the
                          % SelectionChangedFcn callback. Selection
                          % property should be updated before Callbacks are
                          % executed.
                          obj.Model.setSelectionFromClient(selection,...
                              previousSelection,...
                              displaySelection,...
                              previousDisplaySelection);
                          % Fire the CellSelectionCallback in the C++ Model
                          obj.Model.setCellSelectionFromClient(indices, displayIndices);

                      case 'CellDoubleClicked'
                          obj.handleCellDoubleClickedFromView(eventStructure);

                      case 'Clicked'
                          obj.handleClickedFromView(eventStructure);

                      case 'DoubleClicked'
                          obj.handleDoubleClickedFromView(eventStructure);
                      
                      case 'DataRenderedInView'
                          % Used to notify that the uitable data has been
                          % rendered in the view and can be exported
                          obj.DataRenderedInView = true;
                          
                      case 'ColumnRearranged'
                          obj.handleColumnRearrangedFromView(eventStructure);

                      case 'CopyRequested'
                          obj.handleCopyRequestedFromView(eventStructure);

                      case 'LinkClicked'
                          obj.handleLinkClickedfromView(eventStructure);

                      otherwise
                          % Now, defer to the base class for common event processing
                          handleEvent@matlab.ui.internal.componentframework.WebComponentController( obj, src, event );
                  end
                end
            end
        end
    end
    
    methods (Static)
        function index = convertToZeroBasedIndex(oneBasedIndex)
            index = oneBasedIndex - 1;
        end

       function displayData = createDisplayData(model)
            % This method is invoked from the C++ model code.
            % Return the current data table, with rows / columns ordered according to
            % the rowOrder / columnOrder argument.  If rowOrder / columnOrder is not specified, 
            % return the table without reordering.
            displayData = model.Data;
            if ~isempty(model.DisplayRowOrder)
                displayData = displayData(model.DisplayRowOrder, :);
            end
            if ~isempty(model.DisplayColumnOrder)
                displayData = displayData(:, model.DisplayColumnOrder);
            end
       end
        
       %Called by C++, uses getDisplaySelection function
       function displaySelection = createDisplaySelection(obj)
           selection = obj.Model.Selection;
           displaySelection = obj.getDisplaySelection(selection);
       end

       
       function columnVector = convertToColumnVector(vec)
            % convert row vector to column vector
            columnVector = vec;
            if ~iscolumn(vec)
                columnVector = vec';
            end
       end

       % Method to respond when the user clicks a url with a matlab protocol.
       % This is used frequently with the html interpeter.
       function handleLinkClickedfromView(event)
           if ~isempty(event) && ~isempty(event.eventURL)
               try
                   web(event.eventURL, '-browser')
               catch me
                   % MnemonicField is last section of error id
                   mnemonicField = 'failureToLaunchURL';

                   messageObj = message('MATLAB:ui:components:errorInWeb', ...
                       event.eventURL, me.message);

                   warning(['MATLAB:ui:table:' mnemonicField], messageObj.getString())
               end

           else
               %Invalid web url
               mnemonicField = 'failureToLaunchWebURL';
               messageObj = message('MATLAB:ui:components:errorInWebEmpty');
               warning(['MATLAB:ui:table:' mnemonicField], messageObj.getString());
           end
       end
    end
    
    methods
        function data = getSourceData(obj)
            data = obj.Model.Data;            
            
            
            if isempty(data)
                
                % Always reshape the empty data to have 0 rows
                expHeight = 0;
                expWidth = obj.getNumberOfColumnHeaders();

                if istable(data)
                    % Reshape is not supported for table
                    data = table.empty(expHeight, expWidth);
                elseif  ischar(data)
                    % Char is accepted in place of empty, but has no
                    % practial functionality.  Cast this value to double to
                    % enable code reuse.                 
                    data = double.empty(expHeight, expWidth);
                else
                    data = reshape(data, expHeight, expWidth);
                end
                
            end
        end
        
        function sz = getModelDataSize(obj)
            % GETSOURCEDATASIZE - The exact size of the data stored in the Data
            % property.
            sz = size(obj.Model.Data);
            
        end
        
        function formattedData = getFormattedData(obj, displayRows, displayColumns, sourceDataType)
            % GETFORMATTEDDATA - returns a cell array matching the row and
            % column indices of the table data
            
            rowSourceIndices = obj.getSourceRowFromDisplayRow(displayRows);
            colSourceIndices = obj.getSourceColumnFromDisplayColumn(displayColumns);
            formattedData = obj.TextFormatterManager.getFormattedData(obj.Model, rowSourceIndices, colSourceIndices, sourceDataType);
        end

        function formattedData = getFormattedDataRange(obj, startDisplayRow, endDisplayRow, startDisplayCol, endDisplayCol, sourceDataType)
            % GETFORMATTEDDATARANGE - returns a cell array matching the row
            % range and column range of the table data
            
            rowIndices = startDisplayRow:endDisplayRow;
            colIndices = startDisplayCol:endDisplayCol;
            formattedData = obj.getFormattedData(rowIndices, colIndices, sourceDataType);
        end

        function backgroundColor = getBackgroundColor(obj)             
            % When RowStriping is set to 'off', only use first color
            if (strcmp(obj.Model.RowStriping, 'off'))
                backgroundColor = obj.Model.BackgroundColor(1,:);
            else
                backgroundColor = obj.Model.BackgroundColor;
            end
        end
        
        % Whenever RowName is set or table scroll in the view,
        % mw-table and its DataStore will request row names to render for the current page.
        function name = getRowNameForView (obj, row)
            rowNames = obj.Model.RowName;
            if isequal(rowNames, 'numbered') || isempty(rowNames)
               % Hide indices column in row header by setting to NaN.
               name = NaN;
            elseif row < 1 || row > size(rowNames, 1)
                name = '';
            elseif iscell(rowNames)
                name = rowNames{row};   % cell array
            else
                % numeric array
                name = rowNames(row, :); 
            end
        end
        
        % fire CellEditCallback in C++ model.
        function fireCallbacksFromCellEdit(obj, index, displayIndex, editValue, oldValue, newValue, err, valueChanged)
            obj.Model.setEditingCellFromClient(index, displayIndex, editValue, oldValue, newValue, err);
            if valueChanged
                previousDisplaySelection = obj.getDisplaySelection(obj.Model.Selection);
                obj.handleDisplayDataChangedEvent('edit', index(2), previousDisplaySelection);
            end
        end
        
        % Construct Model CellSelection data
        function [indices, displayIndices] = constructSelectedIndices(obj, startRow, endRow, startColumn, endColumn)
            % e.g. convert event data {2, 3, 1, 2} to 
            %   [2 1;
            %    2 2;
            %    3 1;
            %    3 2]
            displayIndices = zeros((endRow-startRow+1)*(endColumn-startColumn+1), 2);
            index = 1;
            for r = startRow:endRow
                for c = startColumn:endColumn
                    displayIndices(index, :) = [r, c];
                    index = index + 1;
                end
            end
            
            % Given the displayIndices of the selected table in the View,
            % find the indices of the selected table cells in the Model
            % Unsort the rows and use the same columns as displayIndices
            rows = obj.getSourceRowFromDisplayRow(displayIndices(:,1));
            cols = obj.getSourceColumnFromDisplayColumn(displayIndices(:,2));
            indices = [rows, obj.convertToColumnVector(cols)];
        end
               
        function sourceRow = getSourceRowFromDisplayRow(obj, displayRow)
            if ~isempty(obj.TableView.SortedRowOrder)
                sourceRow = obj.TableView.SortedRowOrder(displayRow);
            else
                sourceRow = displayRow;
            end
        end
        
        function displayRow = getDisplayRowFromSourceRow(obj, sourceRow)
            if ~isempty(obj.TableView.SortedRowOrder)
                invertedRowOrder = 1: max([numel(obj.TableView.SortedRowOrder) numel(sourceRow) max(sourceRow)]);
                invertedRowOrder(obj.TableView.SortedRowOrder) = 1:numel(obj.TableView.SortedRowOrder);
                displayRow = invertedRowOrder(sourceRow);
            else
                displayRow = sourceRow;
            end
        end
        
        function sourceCol = getSourceColumnFromDisplayColumn(obj, displayCol)
            displayColumnOrder = obj.Model.DisplayColumnOrder;
            if ~isempty(displayColumnOrder)
                sourceCol = displayColumnOrder(displayCol);
            else
                sourceCol = displayCol;
            end
        end
        
        function displayCol = getDisplayColumnFromSourceColumn(obj, sourceCol)
            if ~isempty(obj.Model.DisplayColumnOrder)
                invertedColumnOrder = 1:max([numel(obj.Model.DisplayColumnOrder) numel(sourceCol) max(sourceCol)]);
                invertedColumnOrder(obj.Model.DisplayColumnOrder) = 1:numel(obj.Model.DisplayColumnOrder);
                displayCol = invertedColumnOrder(sourceCol);
            else
                displayCol = sourceCol;
            end        
        end
        
        %% Clear Metadata
        
        function clearCellMetaData(obj, sourceRow, sourceCol)
            % CLEARCELLMETADATA - Notify that the cell metadata has changed
            if isnumeric(sourceRow) && isnumeric(sourceCol)
                displayCol = obj.getDisplayColumnFromSourceColumn(sourceCol);
                displayRow = obj.getDisplayRowFromSourceRow(sourceRow);
                obj.TableView.clearCellMetaData(displayRow, displayCol);
            end
        end
        
        function clearRowMetaData(obj, sourceRow)
            % CLEARROWMETADATA - Notify that the row metadata has changed
            if isnumeric(sourceRow) && size(obj.Model.Data, 1) > 0
                displayRow = obj.getDisplayRowFromSourceRow(sourceRow);
                obj.TableView.clearRowMetaData(displayRow);
            end
        end
        
        function clearColumnMetaData(obj, sourceCol)
            % CLEARCOLUMNMETADATA - Notify that the column metadata has changed
            if isnumeric(sourceCol)
                displayCol = obj.getDisplayColumnFromSourceColumn(sourceCol);
                obj.TableView.clearColumnMetaData(displayCol);
            end
        end
        
        function clearTableMetaData(obj)
            % CLEARTABLEMETADATA - Notify that the table metadata has changed
            obj.TableView.clearTableMetaData();
        end
    end
    
    methods (Access = 'private')

        % get Selection using cell indices coming from view.
        function selection = getSelectionFromView(obj, cellIndices)
            
            if isempty(cellIndices)
                selection = [];
            else 
                switch obj.Model.SelectionType
                    case 'cell'
                        selection = cellIndices;
                    case 'row'
                        % for whole row selection type, convert cell indices to row indices.
                        selection = unique(cellIndices(:, 1))';
                    case 'column'
                        % for whole column selection type, convert cell indices to column indices.
                        selection = unique(cellIndices(:, 2))';
                end
            end
        end

        function displayColumnName = getDisplayColumnName(obj)
            displayColumnName = obj.Model.ColumnName;
            displayColumnOrder = obj.Model.DisplayColumnOrder;
            if ~isempty(obj.Model.DisplayColumnOrder) && ~isequal(obj.Model.ColumnName, 'numbered')
                if numel(obj.Model.ColumnName) < numel(displayColumnOrder)
                    displayColumnOrder(displayColumnOrder > numel(obj.Model.ColumnName)) = [];
                end
                displayColumnName = obj.Model.ColumnName(displayColumnOrder);
            end
        end
        
        % compute DisplaySelection from Selection and DisplayRowOrder
        function displaySelection = getDisplaySelection(obj, selection)
            if isempty(selection)
                displaySelection = selection;
            else
                switch obj.Model.SelectionType
                    case 'cell'
                        rows = obj.getDisplayRowFromSourceRow(selection(:,1));
                        cols = obj.getDisplayColumnFromSourceColumn(selection(:,2));
                        displaySelection = [obj.convertToColumnVector(rows), obj.convertToColumnVector(cols)];
                    case 'row'
                        displaySelection = obj.getDisplayRowFromSourceRow(selection);
                    case 'column'
                        displaySelection = obj.getDisplayColumnFromSourceColumn(selection);
                end
            end
        end
        
        function nColumns = getNumberOfColumnHeaders(obj)
            % GETNUMBEROFCOLUMNHEADERS - The number of column headers is
            % driven by ColumnName and / or Data. If ColumnName is
            % 'numbered', the number of column headers equals number of
            % columns in Data. If ColumnName is empty, the number of column
            % headers is 0. Otherwise, the number of column headers is the
            % maximum value of (number of elements in ColumnName, number of
            % columns in Data).
            
            nColumns = size(obj.Model.Data, 2);
            columnName = obj.Model.ColumnName;
            if nColumns == 0 && ...
                    (iscell(columnName) || ...
                            (ischar(columnName) && ~strcmp(columnName, 'numbered')))

                % Ignore 'numbered'

                % Data is empty, use column name as the width indicator
                % Non-empty options are Cell array or char array 
                nColumns = numel(string(columnName));
            end
        end
        
        function handleDisplayDataChangedEvent (obj, operation, sourceColumn, previousDisplaySelection)

            % Construct DisplayRowName property value for DisplayDataChanged event. 
            if isempty(obj.Model.RowName) || isequal(obj.Model.RowName, 'numbered')
                displayRowName = obj.Model.RowName;
            else
                % Row names need to be re-ordered in the view
                obj.updateRowName();

                rowOrder = obj.Model.DisplayRowOrder;
                if isempty(rowOrder)
                    rowOrder = [1:size(obj.Model.DisplayData, 1)]';
                end
                if size(obj.Model.RowName, 1) < size(rowOrder, 1)
                    % need to expand row names vector first.
                    % g1894702
                    diff = size(rowOrder, 1) - size(obj.Model.RowName, 1);
                    if iscell(obj.Model.RowName)
                        displayRowName = [obj.Model.RowName; repmat({''}, diff, 1)];
                    else
                        displayRowName = [obj.Model.RowName; repmat(' ', diff, size(obj.Model.RowName, 2))];
                    end
                    displayRowName = displayRowName(rowOrder,:);
                else
                    if iscell(obj.Model.RowName)
                        % cell array
                        displayRowName = {obj.Model.RowName{rowOrder}}';
                    else
                        % char array
                        displayRowName = obj.Model.RowName(rowOrder,:);
                    end
                end
            end

            % InteractionVariable only exists for table data. Otherwise,
            % it is an empty string ''
            if istable(obj.Model.Data)
                interactionVariable = obj.Model.Data.Properties.VariableNames{sourceColumn};
            else
                interactionVariable = '';
            end

            displaySelection = obj.getDisplaySelection(obj.Model.Selection);
            displayColumnName = obj.getDisplayColumnName();

            obj.Model.processDisplayDataChangedEvent( ...
                displayRowName, ...          % DisplayRowName
                displayColumnName, ...    % DisplayColumnName - may change when column rearrangement is implemented 
                displaySelection,...         % DisplaySelection - Selected cell / row / column indices reflecting the view version of Data
                previousDisplaySelection,... % PreviousDisplaySelection - Previously selected cell / row / column indices reflecting the view version of Data
                operation, ...               % Interaction
                sourceColumn, ...             % InteractionColumn
                obj.getDisplayColumnFromSourceColumn(sourceColumn), ... % InteractionDisplayColumn - may change when column rearrangement is implemented 
                interactionVariable );       % InteractionVariable
        end
    end


    % private util methods
    methods (Access = 'protected')
        
        % handle column rearranged event from view.
        function handleColumnRearrangedFromView (obj, eventStructure)
            if isempty(obj.Model.DisplayColumnOrder)
                nColumns = obj.getNumberOfColumnHeaders();
                obj.Model.DisplayColumnOrder = 1:nColumns;
            end

            % cache DisplaySelection
            previousDisplaySelection = obj.getDisplaySelection(obj.Model.Selection);
            
            % if multiple columns are rearranged at once, fromIndex (display indices of columns to be moved) will be
            % a vector. For instance, [2 5 7] when columns at positions 2,5 and 7 are
            % all dragged at once to the location toIndex (display index of the new location). Otherwise,
            % fromIndex will be the index of the column being dragged.
            fromIndex = eventStructure.fromIndex;
            toIndex = eventStructure.toIndex;
            
            % the columns in the fromIndex locations are going to be moved
            % to toIndex.
            % Consider DisplayColumnOrder [5 1 4 2 3], fromIndex = [2 4],
            % toIndex = 1
            % First we cache the columns in the fromIndex. fromIndexVal =
            % [1 2]
            % Second we delete the columns in the fromIndex. DisplayColumnOrder [5 4 3]
            % Third we add the cached columns to the location toIndex. DisplayColumnOrder [1 2 5 4 3]
            fromIndexVal = obj.Model.DisplayColumnOrder(fromIndex);
            obj.Model.DisplayColumnOrder(fromIndex) = [];
            numOfEl = numel(obj.Model.DisplayColumnOrder);
            
            if toIndex > numOfEl
                obj.Model.DisplayColumnOrder = [obj.Model.DisplayColumnOrder fromIndexVal];
            else
                obj.Model.DisplayColumnOrder = [obj.Model.DisplayColumnOrder(1:toIndex-1) fromIndexVal obj.Model.DisplayColumnOrder(toIndex:end)];
            end
            
            % Update table properties
            obj.updateColumnName();
            obj.updateColumnFormat();
            obj.updateColumnWidth();
            obj.updateColumnSortable();
            obj.updateColumnEditable();

            % Update data in view
            startDisplayRow = 1;
            endDisplayRow = size(obj.Model.Data, 1);
            startDisplayColumn = min(fromIndex, toIndex);
            endDisplayColumn = max(fromIndex, toIndex);

            %Set GroupColumnSize for multi column
            obj.TableView.setViewGroupColumnSize(obj.Model.Data);

            obj.TableView.updateViewDataRange(startDisplayRow, endDisplayRow, startDisplayColumn, endDisplayColumn);

            % Update view DataType
            obj.TableView.setViewDataType(obj.Model.Data);
            

            % Update paged data like addStyles
            if obj.StylesManager.hasStylesTable
                rowsToClear = obj.getSourceRowFromDisplayRow(startDisplayRow:endDisplayRow);
                columnsToClear = obj.getSourceColumnFromDisplayColumn(startDisplayColumn:endDisplayColumn);
                % update style for all columns which shifted location as a
                % result of rearranging columns.
                obj.clearColumnMetaData(columnsToClear);
                obj.clearCellMetaData(rowsToClear, columnsToClear);
            end
            
            % Update cell configurations when there are mixed content in
            % columns
            obj.TableView.clearCellMetaDataForMixedCells()

            % update selection in the view.
            viewSelection = obj.updateSelection();
            obj.EventHandlingService.setPropertyAndCommit('Selection', viewSelection);
            
            obj.handleDisplayDataChangedEvent("rearrange", fromIndexVal, previousDisplaySelection)
        end
        
        % handle sorting event from view.
        function handleSortingFromView (obj, eventStructure)
            
              % Client column index is 0 ordered.
              sourceColumn = obj.getSourceColumnFromDisplayColumn(eventStructure.ColumnIndex + 1);
              direction = eventStructure.SortOrder;

              % Cache DisplaySelection before sort
              previousDisplaySelection = obj.getDisplaySelection(obj.Model.Selection);
              
              rowOrder = obj.TableView.sortTable(sourceColumn, direction);
              % Cache DisplayRowOrder in the Model so it's
              % available even if controller is not present.
              obj.Model.DisplayRowOrder = rowOrder;

              
              obj.handleDisplayDataChangedEvent('sort', sourceColumn, previousDisplaySelection);
              
              % update selection in the view.
              viewSelection = obj.updateSelection();
              obj.EventHandlingService.setPropertyAndCommit('Selection', viewSelection);
        end
        
        % handle cell double-click event from view
        function handleCellDoubleClickedFromView (obj, eventdata)
            [modelIndex, displayIndex] = obj.constructSelectedIndices(eventdata.startRow+1, ...
                                                                      eventdata.endRow+1, ...
                                                                      eventdata.startColumn+1, ...
                                                                      eventdata.endColumn+1);
            obj.Model.processCellDoubleClickedEvent(modelIndex, displayIndex);
        end

        % handle click event from view
        function handleClickedFromView (obj, eventdata)
            interactionInformation = obj.constructInteractionInformation(eventdata);
            obj.Model.notify('Clicked',matlab.ui.eventdata.ClickedData(interactionInformation));
        end

        % handle double click event from view
        function handleDoubleClickedFromView (obj, eventdata)
            interactionInformation = obj.constructInteractionInformation(eventdata);
            obj.Model.notify('DoubleClicked',matlab.ui.eventdata.DoubleClickedData(interactionInformation));
        end

        function interactionObject = constructInteractionInformation(obj, eventdata)
            % Construct row and column data
            interactionInformation = obj.constructRowAndColumnInteractionInformation(eventdata);

            % Location data
            interactionInformation.LocationOffset = eventdata.localOffset;
            interactionInformation.Source = obj.Model;

            interactionObject = obj.constructInteractionObject(interactionInformation);
        end

        function interactionInformation = constructRowAndColumnInteractionInformation(obj, eventdata, interactionInformation)
            displayRow = [];
            displayCol = [];

            if ~isempty(eventdata.row)
                displayRow = eventdata.row + 1;
            end

            if ~isempty(eventdata.col)
                displayCol = eventdata.col + 1;
            end

            if isempty(obj.Model.DisplayRowOrder)
                row = displayRow;
            else
                row = obj.Model.DisplayRowOrder(displayRow);
            end

            if isempty(obj.Model.DisplayColumnOrder)
                col = displayCol;
            else
                col = obj.Model.DisplayColumnOrder(displayCol);
            end

            % Construct InteractionInformation
            % Table-specific event data
            interactionInformation.DisplayRow = displayRow;
            interactionInformation.DisplayColumn = displayCol;
            interactionInformation.Row = row;
            interactionInformation.Column = col;
            interactionInformation.RowHeader = eventdata.rowHeader;
            interactionInformation.ColumnHeader = eventdata.colHeader;
        end
        
        % handle copy request from view
        function handleCopyRequestedFromView (obj, eventStructure)
            % g2466438: Get the selected view indices from the client since
            % sorting does not update the selection on the Model.
            % Shifting from 0 based indexing since the selection ranges are
            % coming from JS to 1 based indexing for MATLAB.
            sRows = eventStructure.selectedRows + 1;
            sCols = eventStructure.selectedColumns + 1;

            % getFormattedData to push to the clipboard
            selectedData = obj.getFormattedData(sRows, sCols, obj.TableView.SourceDataType);
            
            %Grouped columns should be copied as their own columns
            selectedData = obj.expandGroupedColumns(selectedData);

            % Format the data for the clipboard using Tabs for columns and Newlines for rows.
            % g3501732: Do not put a tab at the end of each line and do not trim whitespace
            evalString = arrayfun(@(x) [sprintf('%s\t', selectedData{x,1:end-1}), selectedData{x,end}], [1:height(selectedData)], 'UniformOutput', false);
            evalString = strjoin(evalString, '\n');
            clipboard('copy',evalString);
        end
        
        % To show/hide row name column, need to notify client controller to
        % re-create mw-table.
        function updateRowHeaderColumn(obj)
            showRowHeader = ~isempty(obj.Model.Data) && ~isempty(obj.Model.RowName);
            showRowHeaderNumber = isequal('numbered', obj.Model.RowName);
            rowHeaderColumnChanged = (~obj.HasRowHeader && showRowHeader) || ... show row header column.
                                     (obj.HasRowHeader && ~showRowHeader) || ... hide row header column.
                                     (obj.HasRowHeaderNumber && ~showRowHeaderNumber) || ... show row header numbers.
                                     (~obj.HasRowHeaderNumber && showRowHeaderNumber);  % hide row header numbers.
                                   
            % notify client
            if rowHeaderColumnChanged
                obj.EventHandlingService.setPropertyAndCommit('RowHeaderOptions', [showRowHeader showRowHeaderNumber]);
            end
            
            % update HasRowHeader status
            obj.HasRowHeader = showRowHeader;
            obj.HasRowHeaderNumber = showRowHeaderNumber;
        end
        
        % To show/hide column header, need to notify client 
        function updateColumnHeaderVisibility(obj)
            showColumnName = ~isempty(obj.Model.ColumnName);
            showColumnHeader = '';
            if ~obj.HasColumnName && showColumnName % show column header 
                showColumnHeader = true;
            end
            if obj.HasColumnName && ~showColumnName % hide column header
                showColumnHeader = false;
            end
            
            if ~isempty(showColumnHeader)
                obj.EventHandlingService.setPropertyAndCommit('ShowColumnHeader', showColumnHeader);
            end
            % update HasColumnName status
            obj.HasColumnName = showColumnName;
        end
        
        function updateTableStyle(obj)
            % UPDATETABLESTYLE - Constructs table-level styling metadata 
            % and notifies datastore to update the view with the new styles
            
            % ForegroundColor
            c = round(255 * obj.Model.ForegroundColor);
            newForegroundColor = ['#' dec2hex(c(1),2) dec2hex(c(2),2) dec2hex(c(3),2)];
            
            % FontName
            newFontName = strcat(matlab.ui.internal.FontUtils.getFontForView(obj.Model.FontName), ', Helvetica, sans-serif');

            % FontSize
            fontUnits = obj.convertFontUnits(obj.Model.FontUnits);
            
            newFontSize = obj.convertFontSize(obj.Model,  obj.Model.FontUnits,...
                                              obj.Model.FontSize, fontUnits);
            % FontAngle
            newFontAngle = obj.Model.FontAngle;
            
            % FontWeight
            newFontWeight = obj.Model.FontWeight;
            
            % g2384803 support the undocumented font Weight properties demi | light
            % to behave as normal font weight
            if isequal(newFontWeight, 'demi') || isequal(newFontWeight, 'light')
                newFontWeight = 'normal';
            end    
            
            styleStruct = struct('color', newForegroundColor, ...
                  'fontFamily', newFontName, ...
                  'fontSize', newFontSize, ...
                  'fontStyle', newFontAngle, ...
                  'fontWeight', newFontWeight);
              
            obj.TableView.setViewTableStyle(styleStruct);
        end
        
        function value = convertFontSize(~, model, fUnits, fSize, shortUnits)
            switch fUnits
                case 'normalized'
                    value = strcat(num2str(model.getFontSizeInPixels()), shortUnits);
                otherwise
                    value = strcat(num2str(fSize), shortUnits);
            end
        end
       
        function value = convertFontUnits(~, value)
            if(isequal(value, 'points'))
                value = 'pt';
            elseif(isequal(value, 'inches'))
                value = 'in';
            elseif(isequal(value, 'centimeters'))
                value = 'cm';
            elseif(isequal(value, 'pixels'))
                value = 'px';
            elseif(isequal(value, 'normalized'))
                % If the value is normalized, we want to set the view in
                % pixels after doing the appropriate unit conversions to
                % pixels.
                value = 'px';
            end
		end

		% Check if a datatype is editable
        function isEditable = isEditableDataType (obj, data, index)
            isEditable = false;
            
            if istable(data)
                colData = data.(index);
                % multi-column variable is not editable.
                if size(colData, 2) > 1
                    return;
                end
            else
                colData = data(:, index);
            end

            if iscellstr(colData) || ...   % cell array of characters
               isnumeric(colData) || ...   % any numeric data type
               iscell(colData) || ...      % mixed cell data
               any(string(class(colData)) == ["string", "logical", "datetime", "categorical"])
                % return true for all editable data types.
                isEditable = true;
            end
        end
        
        function name = replacePipeWithNewline(obj, name)
            if ~isnumeric(name)
                name = replace(name, '|', newline);
            end
        end
    end
    methods(Static)
        function expandedData  = expandGroupedColumns(tableData)
            expandedData = tableData; % Shouldnt actually make a copy until needed

            %Track where to insert the next grouped column into
            ColumnToInsertAfter = 0;

            %Iterate over every column
            for tableColumn = 1:width(tableData)

                %Check if the column is grouped
                if iscell(tableData{1,tableColumn})

                    %Unpack the column so instead of a 1 column of 1xn
                    %arrays, create n columns.
                    NewColumns = vertcat(tableData{:,tableColumn});
                    expandedData = [expandedData(:,1:ColumnToInsertAfter),NewColumns,expandedData(:,ColumnToInsertAfter+2:end)];
                    [~,columnsAdded] = size(NewColumns);

                    %Next time you encounter a group column, make sure to
                    %account for the new columns
                    ColumnToInsertAfter = ColumnToInsertAfter + columnsAdded;
                else
                    ColumnToInsertAfter = ColumnToInsertAfter + 1;
                end
            end
        end
    end
end
