classdef DesignTimeTableController < ...
        matlab.ui.internal.controller.uitable.WebMWTableController & ...
        matlab.ui.internal.DesignTimeGBTComponentController & ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DesignTimeTableController A table controller class which encapsulates
    % the design-time specific dta and behaviour and establishes the
    % gateway between the Model and the View

    % Copyright 2015-2023 The MathWorks, Inc.

    methods

        function obj = DesignTimeTableController( model, parentController, proxyView, adapter)
            %CONSTRUCTURE

            %Input verification
            narginchk( 4, 4 );

            % Construct the run-time controller first
            obj = obj@matlab.ui.internal.controller.uitable.WebMWTableController( model, parentController, proxyView );

            % Construct the DesignTimeGBTComponentController last to ensure
            % controller injection, and view attaching finished from
            % run-time WebComponentController
            obj = obj@matlab.ui.internal.DesignTimeGBTComponentController(model, parentController, proxyView, adapter);

            % create design-time table view implementation.
            if ~isempty(obj.ViewModel)
                obj.createDesignTimeTableViewWithPeerNode();
            end

        end

        function createDesignTimeTableViewWithPeerNode (this)
            % Once we have server side ready,
            % propagate all properties from mode to view

            % Invoke triggerUpdatesOnDependentViewProperties and postAdd
            % method before firing server ready event. This ensures that
            % Column Metadata Defaults are set when server ready is fired.
            % g2458434
            this.triggerUpdatesOnDependentViewProperties();

            % Manually trigger updates for non-peernode table
            % configurations reflected in the canvas
            % TODO: Replacing these three with a call to postAdd would send
            % all properties to the view but currently marks apps dirty in error.
            this.updateColumnName();
            this.updateColumnWidth();
            this.updateColumnSortable();

            this.fireServerReadyEvent();
        end

        % Override MCF's update method ONLY for design time table for its
        % Server-driven properties like Data.
        % Unlike run time, updating property in design time will only call update methods,
        % but not erase values in PeerNode.
        function triggerUpdateOnDependentViewProperty( obj, property )
            obj.("update" + property);
        end
    end

    methods (Access=protected)
        function handleDesignTimePropertyChanged(obj, peerNode, data)

            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time. For
            % property updates that are common between run time and design time,
            % this method delegates to the corresponding run time controller.

            % Handle property updates from the client

            updatedProperty = data.key;
            updatedValue = data.newValue;

            switch ( updatedProperty )
                case 'ColumnSortable'
                    if (isa(updatedValue, 'double'))
                        updatedValue = logical(updatedValue);
                    end

                    obj.Model.ColumnSortable = updatedValue;

                    if obj.ServerReady
                        obj.setProperty('ColumnSortable_I');
                    end

                case 'ColumnName'
                    % Set ColumnName
                    obj.Model.ColumnName = updatedValue;
                    % TODO for Zhengwen: Add comments for the next line
                    if obj.ServerReady
                        obj.setProperty('ColumnName_I');
                    end

                case 'ColumnWidth'
                    if(strcmp(updatedValue, 'auto'))
                        obj.Model.ColumnWidth = reshape(updatedValue, 1, length(updatedValue));
                    elseif(isa(updatedValue , 'double'))
                        % g1383730
                        % When all values are numeric,
                        % it comes in as a 1* n double array but
                        % this is not an allowed input for ColumnWidth
                        % Transform this value into a 1* n cell array
                        obj.Model.ColumnWidth = num2cell(updatedValue);
                    else
                        obj.Model.ColumnWidth = updatedValue;
                    end

                    if obj.ServerReady
                        obj.setProperty('ColumnWidth_I');
                    end

                case 'RowName'

                    % Corce arrays of 1 to a string
                    %
                    % This enables the case when the user types in
                    % 'numbered'.  This comes over as {'numbered'} and
                    % needs to be be converted to 'numbered'
                    if(iscell(updatedValue) && length(updatedValue) == 1 && strcmp(updatedValue{1}, 'numbered'))
                        updatedValue = updatedValue{1};
                    end

                    % Any empty value ([], '', {}, {''}) should be
                    % converted to {}.
                    % {''} is treated as an empty value because clearing the
                    % property inspector entry for RowName will register a
                    % value of {''} on the server.  This allows us to fully
                    % clear RowName when the user clears RowName. See g2089062.
                    if(isempty(updatedValue) || ...
                            (iscellstr(updatedValue) && (length(updatedValue) == 1) && isempty(updatedValue{1})))

                        updatedValue = {};
                    end

                    obj.Model.RowName = updatedValue;
                    if obj.ServerReady
                        obj.setProperty('RowName_I');
                    end

                case 'RowStriping'
                    obj.Model.RowStriping = updatedValue;
                    if obj.ServerReady
                        obj.setProperty('RowStriping');
                    end

                case 'data'
                    % Mouse interactions event data; not the same as the
                    % UITable's 'Data' property.
                    % Do not set on component model - view-only property
                    % no-op

                otherwise
                    % call base class to handle it
                    handleDesignTimePropertyChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, data);
            end
        end


        function handleDesignTimeEvent(obj, src, event)
            % Handler for 'peerEvent' from the Peer Node

            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                % Handle changes in the property editor that needs a
                % server side validation

                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;

                if(any(strcmp(propertyName, {'ColumnSortable'})))

                    if (isa(propertyValue, 'double'))
                        propertyValue = logical(propertyValue);
                    end

                    setServerSideProperty(obj, ...
                        obj.Model, ...
                        propertyName, ...
                        propertyValue, ...
                        event.Data.CommandId...
                        )

                    % Synchronize Peer Nodes
                    if obj.ServerReady
                        obj.ViewModel.setProperties({"ColumnSortable", obj.Model.ColumnSortable});
                        obj.setProperty('ColumnSortable');
                        obj.setProperty('ColumnSortable_I');
                    end

                    % stop handling other events
                    return;
                end

                if(any(strcmp(propertyName, {'ColumnWidth'})))

                    % Convert a value of all numbers to a cell of numbers
                    %
                    % UITable API does not accept [10 10 20] for example
                    if(isnumeric(propertyValue))
                        propertyValue = num2cell(propertyValue);
                    end

                    setServerSideProperty(obj, ...
                        obj.Model, ...
                        propertyName, ...
                        propertyValue, ...
                        event.Data.CommandId...
                        )

                    % Synchronize Peer Nodes
                    if obj.ServerReady
                        obj.ViewModel.setProperties({"ColumnWidth", obj.Model.ColumnWidth});
                        obj.setProperty('ColumnWidth');
                        obj.setProperty('ColumnWidth_I');
                    end

                    % stop handling other events
                    return;
                end

                if(any(strcmp(propertyName, {'ColumnEditable'})))

                    setServerSideProperty(obj, ...
                        obj.Model, ...
                        propertyName, ...
                        propertyValue, ...
                        event.Data.CommandId...
                        )

                    % Synchronize Peer Nodes
                    if obj.ServerReady
                        % Unsure why this extra call needs to be done on
                        % the Peer Node
                        obj.ViewModel.setProperties({"ColumnEditable", obj.Model.ColumnEditable});
                        obj.setProperty('ColumnEditable');
                        obj.setProperty('ColumnEditable_I');
                    end

                    % stop handling other events
                    return;
                end
            end

            % Defer to super
            handleDesignTimeEvent@matlab.ui.internal.DesignTimeGBTComponentController(obj, src, event);
        end

        function handleDesignTimePropertiesChanged(obj, src, changedPropertiesStruct)
            % HANDLEDESIGNTIMEPROPERTIESCHANGED - Override the superclass
            % method in order to provide additional logic when certain
            % properties have changed.

            % Call the method on the super class.
            handleDesignTimePropertiesChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj,src, changedPropertiesStruct);

            % When the table's size is changed, the column widths should be
            % recalculated and the column headers should be rerendered.
            % This ensures that the column headers fill the entire
            % available space within the table.
            if isfield(changedPropertiesStruct, 'Size')
                obj.triggerUpdatesOnDependentViewProperties();
            end
        end

        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties
            % 2) FontUnits required by client side

            additionalPropertyNamesForView = {
                'ColumnEditable'; ...
                'ColumnSortable'; ...
                'ColumnName'; ...
                'ColumnRearrangeable'; ...
                'Multiselect'; ...
                'RowName'; ...
                'ColumnFormat'; ...
                'BackgroundColor'; ...
                'ForegroundColor'; ...
                'ColumnWidth'; ...
                'RowStriping'; ...
                'CellEditCallback'; ...
                'CellSelectionCallback'; ...
                'SelectionChangedFcn'; ...
                'FontUnits'; ...
                'FontName'; ...
                'FontWeight'; ...
                'FontAngle'; ...
                'ColumnSortable'; ...
                'DisplayDataChangedFcn'; ...
                'ButtonDownFcn'; ...
                'KeyPressFcn'; ...
                'KeyReleaseFcn'; ...
                'ClickedFcn'; ...
                'DoubleClickedFcn'
                };

            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];

        end

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Children, Parent, are not needed by the view
            % - Position, InnerPosition, OuterPosition are not updated by
            % the view and are excluded so their peer node values don't
            % become stale

            excludedPropertyNames = {'ColumnFormat'; 'EnableDoubleClickedEditing'};

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];

        end
    end
end
