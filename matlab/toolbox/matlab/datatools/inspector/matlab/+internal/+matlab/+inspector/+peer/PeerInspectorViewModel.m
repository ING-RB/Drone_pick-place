classdef PeerInspectorViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.inspector.InspectorViewModel

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % PeerViewModel for the Inspector.

    % Copyright 2015-2025 The MathWorks, Inc.

    properties(Access = private)
        propertyChangedListener = [];
        propertyRemovedListener = [];
        propertyAddedListener = [];
        MetaDataChangedListener = [];
        PropMetadataChangedListener = [];
        AutoRefreshChangedListener = [];
    end

    events
        PropertyEdited
    end

    properties(Access = public)
        UndoQueue;
        ObjectActionCallback; % callback for object action event used in the Object browser
        MsgSvcChannel = "/PropertyInspector";
    end

    properties(Hidden)
        ErrorFcn function_handle = function_handle.empty;
    end

    properties(Hidden, Constant)
        RESTRICTED_COMMANDS = ["exit", "pause", "input"];
        DYNAMIC_CLASSNAME_SEPARATOR = '^';
    end

    methods
        % Constructor - creates a new PeerInspectorViewModel for the given
        % parentNode and variable
        function this = PeerInspectorViewModel(document, variable, viewID)
            if nargin <= 2
                viewID = '';
            end

            this@internal.matlab.inspector.InspectorViewModel(...
                variable.DataModel, viewID);

            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'type', 'inspector', 'viewID', viewID);

            % Set the channel for this view model
            this.MsgSvcChannel = document.Manager.Channel;

            % Create listener for property changed events
            this.propertyChangedListener = event.listener(...
                variable.DataModel, 'PropertyChanged', ...
                @(es,ed) this.handlePropertyChanged(es, ed));
            this.propertyRemovedListener = event.listener(...
                variable.DataModel, 'PropertyRemoved', ...
                @(es,ed) this.handlePropertyRemoved(es, ed));
            this.propertyAddedListener = event.listener(...
                variable.DataModel, 'PropertyAdded', ...
                @(es,ed) this.handlePropertyAdded(es, ed));
            this.MetaDataChangedListener = event.listener(...
                variable.DataModel, 'MetaDataChanged', ...
                @(es,ed) this.handleMetaDataChanged(es, ed));
            this.PropMetadataChangedListener = event.listener(...
                variable.DataModel, 'PropertyMetadataChanged', ...
                @(es,ed) this.handlePropMetadataChanged(es, ed));

            this.AutoRefreshChangedListener = event.listener(...
                variable.DataModel, 'AutoRefreshChanged', ...
                @(es,ed) this.handleAutoRefreshChanged(es, ed));
            % Property Inspector doesn't use the DataChanged listener
            delete(this.DataChangeListener);

            s = size(properties(variable.DataModel.getData));
            this.ViewportStartColumn = 1;
            this.ViewportStartRow = 1;
            this.ViewportEndColumn = 4;
            this.ViewportEndRow = s(1);
            this.refreshRenderedData(struct('startRow', 1, 'endRow', s(1), ...
                'startColumn', 1, 'endColumn', 1));
        end

        function [renderedData, renderedDims] = refreshRenderedData(this, varargin)
            % Fetches latest rendered data and sends an update to the
            % client with that data block.
            startRow = this.getStructValue(varargin{1}, 'startRow') + 1;
            endRow = this.getStructValue(varargin{1}, 'endRow') + 1;
            startColumn = this.getStructValue(varargin{1}, 'startColumn') + 1;
            endColumn = this.getStructValue(varargin{1}, 'endColumn') + 1;
            limitCount = this.getStructValue(varargin{1}, 'limitCount');

            if ~isvalid(this.DataModel.getData)
                % Early return for invalid data
                renderedData = {};
                renderedDims = [0,0];
                return;
            end

            dataDispatched = false;
            if isa(this.DataModel.getData, 'internal.matlab.inspector.InspectorProxyMixin')
                renderedData = [];
                locale = feature('locale');
                if ~isempty(this.DataModel.getData.CurrRenderedData)
                    % Use rendered data stored in the proxy object
                    renderedData = this.DataModel.getData.CurrRenderedData;
                elseif startsWith(locale.messages, "en_US")
                    % See if the rendered data for this object is available
                    % through the factory.  Only do this for English, since
                    % that's the language used for the build time cache.
                    inspectedObj = this.DataModel.getData.OriginalObjects;
                    if this.useDataFromCacheForObj(inspectedObj)
                        viewClass = internal.matlab.inspector.peer.InspectorFactory.getInspectorViewName(class(inspectedObj), "default", inspectedObj);
                        rdm = internal.matlab.inspector.peer.InspectorFactory.getInstance.RenderedDataMap;
                        if isKey(rdm, viewClass)
                            renderedData = rdm(viewClass);
                            if ~isempty(renderedData) && ~isempty(this.DataModel.MetaDataHandler)
                                % Add in the Object Browser data from the
                                % MetaDataHandler.  It isn't here because we're
                                % using the cached data, which doesn't include a
                                % hierarchy.
                                rdEnd = renderedData{end};
                                renderedData = renderedData(1:end-1);
                                renderedData = this.addInObjectBrowserData(renderedData, length(renderedData));
                                renderedData{end+1} = rdEnd;
                            end
                        end
                    end
                end

                if ~isempty(renderedData)
                    % We have the data cached - immediately dispatch it back to the
                    % client.
                    this.dispatchSetDataEvent(startRow, endRow, startColumn, ...
                        endColumn, renderedData)

                    dataDispatched = true;
                end
            end

            if dataDispatched
                % Dispatch an update containing the current data after the
                % inspector has a chance to display
                range = [startRow, endRow, startColumn, endColumn];
                if internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
                    this.postDispatchUpdate(range);
                else
                    builtin('_dtcallback', @() this.postDispatchUpdate(range));
                end
                return;
            end

            % Get the latest rendered data and dimensions
            renderedData = this.getRenderedData(...
                startRow, endRow, startColumn, endColumn, limitCount);
            
            if isa(this.DataModel.getData, 'internal.matlab.inspector.InspectorProxyMixin') && ...
                    isequal(limitCount, endRow)
                % Cache the latest data if possible, and the request is to
                % retrieve the full set of data.  (If this is the first page of
                % data retrieved, the limitCount will be smaller than the end
                % row)
                this.DataModel.getData.CurrRenderedData = renderedData;
            end

            % Dispatch a peer event with the data if it hasn't been
            % previously dispatched
            this.dispatchSetDataEvent(startRow, endRow, startColumn, ...
                endColumn, renderedData)

            renderedDims = size(renderedData);
        end

        function postDispatchUpdate(this, range)
            % Dispatch an update containing the current data after the inspector
            % has a chance to display
            try
                renderedData = this.getRenderedData(range(1), range(2), range(3), range(4), []);
                this.dispatchSetDataEvent(range(1), range(2), range(3), range(4), renderedData);
                this.DataModel.getData.CurrRenderedData = renderedData;
            catch
                % ignore errors, can happen when inspected objects change
            end
        end

        function propList = getLimitedPropertyList(~, groups, limitCount, propList)
            % Get a limited property list, limited to approximately the
            % limit count.  Considers the properties of the groups in
            % order, and constructs a list of the visible properties (not
            % in sub groups), until the limit count is hit (but completes
            % the current group)
            if ~isempty(groups)
                for groupRow = 1:length(groups)
                    groupPropertyList = groups(groupRow).PropertyList;
                    for p = 1:length(groupPropertyList)
                        if ischar(groupPropertyList{p})
                            propList = [propList groupPropertyList{p}]; %#ok<*AGROW>
                        elseif isa(groupPropertyList{p}, 'internal.matlab.inspector.InspectorSubGroup')
                            subgroup = groupPropertyList{p};
                            if ischar(subgroup.PropertyList{1})
                                propList = [propList subgroup.PropertyList{1}];
                            else
                                sg = subgroup.PropertyList{1};
                                propList = [propList sg.PropertyList{1}];
                            end
                        else
                            propList = [propList groupPropertyList{p}.PropertyList];
                        end
                    end
                    if length(propList) > limitCount
                        break;
                    end
                end
            end
        end

        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn, limitCount, propList)
            % Overrides the getRenderedData so that the Group information
            % can be added.
            timerRunning = this.DataModel.isTimerRunning();
            this.DataModel.pauseTimer();

            rawData = this.getData();
            if isa(rawData, "internal.matlab.inspector.DefaultInspectorProxyMixin") && ...
                    isa(rawData.getOriginalObjectAtIndex(1), "internal.matlab.inspector.EmptyObject")
                % The timer doesn't run for the EmptyObject, but we don't need
                % to show the warning about it either.
                timerRunning = true;
            end
            groups = rawData.getGroups();

            if nargin < 7
                propList = strings(0,0);
            end

            pagedData = false;
            if nargin == 6 && ~isempty(limitCount) && limitCount < length(fieldnames(rawData))
                propList = this.getLimitedPropertyList(groups, limitCount, propList);
                pagedData = true;
            end

            % Get the rendered data from the PeerObjectViewModel
            [propertySheetData, objectValueData, propsDims] = this.renderData(...
                startRow, endRow, startColumn, endColumn, propList);
            % Sort the property sheet and object value content, to assure
            % consistent ordering across platforms.
            propertySheetData = sort(propertySheetData);
            objectValueData = sort(objectValueData);

            % Get the group data
            if isempty(this.DataModel.getData.CurrRenderedGroupData)
                % If it isn't cached on the object, retrieve it and save it on
                % the Proxy object
                groupData = this.getRenderedGroupData();
                this.DataModel.getData.CurrRenderedGroupData = groupData;
            else
                % Use the cached data.  This doesn't change for an instance of
                % an object.
                groupData = this.DataModel.getData.CurrRenderedGroupData;
            end

            idx = 1;
            % Create a cell array of the appropriate size
            renderedData = cell(propsDims(1) + size(groupData, 1) + 2, 1);
            renderedData{idx,1} = sprintf('{\n\t"propertySheet":{\n\t\t"properties": [\n');
            idx = idx + 1;
            % Add in the properties from the propsData retrieved above
            for i = 1:propsDims(1)
                if (i>1)
                    renderedData{idx-1,1} = [renderedData{idx-1,1} ','];
                end
                renderedData{idx,1} = propertySheetData{i};
                idx = idx + 1;
            end

            if ~isempty(groupData)
                % Add in the groups, if there are any defined
                renderedData{idx,1} = sprintf('\t\t],\n\t\t"groups": [\n');
                idx = idx+1;
                for j = 1:size(groupData, 1)
                    if (j>1)
                        renderedData{idx-1,1} = [renderedData{idx-1,1} ','];
                    end
                    renderedData{idx,1} = groupData{j};
                    idx = idx + 1;
                end
            end

            renderedData{idx,1} = sprintf('\t\t]},\n');
            idx = idx + 1;

            renderedData{idx,1} = sprintf('\t"objects":[{\n');
            idx = idx + 1;
            for i = 1:propsDims(1)
                if (i>1)
                    renderedData{idx-1,1} = [renderedData{idx-1,1} ','];
                end
                renderedData{idx,1} = objectValueData{i};
                idx = idx + 1;
            end
            renderedData{idx,1} = sprintf('\t\t}],\n');

            % get the meta data if exists
            if ~isempty(this.DataModel.MetaDataHandler)
                [renderedData, idx] = this.addInObjectBrowserData(renderedData, idx);
            end

            % Add in timerRunning flag.
            % TODO: All of this should just create a structure to serialize afterwards
            idx = idx + 1;
            if timerRunning
                renderedData{idx,1} = sprintf('\t"timerRunning":true,');
            else
                renderedData{idx,1} = sprintf('\t"timerRunning":false,');
            end

            if ~this.DataModel.getData.ShowInspectorToolstrip
                idx = idx + 1;
                renderedData{idx,1} = sprintf('\t"showInspectorToolstrip":false,');
            end

            % Add in an ID to be used for caching on the client.  (Currently
            % this is just the classname (the proxy or the original class)
            idx = idx + 1;
            varClass = class(rawData);
            if any(varClass == ["internal.matlab.inspector.DefaultInspectorProxyMixin", ...
                    "matlab.graphics.internal.propertyinspector.views.ComponentContainerView", ...
                    "internal.matlab.inspector.UIComponentProxy", ...
                    "internal.matlab.inspector.ValueObjectWrapper", ...
                    "internal.matlab.inspector.StructWrapper"])
                % Can compare class names because these are explicit classes
                % that the Property Inspector creates itself
                varClass = class(rawData.getOriginalObjectAtIndex(1));
            elseif isa(rawData, "internal.matlab.inspector.ProxyAddPropMixin") || ...
                    ~isempty(rawData.UserRichEditorUIMap)
                % These classes may have properties which come/go, so try to
                % prevent client-side caching by creating a unique id.  Use
                % a '^' as the separator, as it isn't something that could
                % be in a MATLAB class name.
                varClass = sprintf('%s%s%d', class(rawData.getOriginalObjectAtIndex(1)), ...
                    this.DYNAMIC_CLASSNAME_SEPARATOR, floor(abs(randn*100)));
            end

            if pagedData
                % Add a special prefix to the ID so we know this is the initial
                % page of properties.  We don't want the initial page of
                % properties to be cached -- passing a special prefix will
                % prevent this.
                varClass = ['__pagedata__' varClass];
            end
            renderedData{idx,1} = sprintf(['\t"id":"' varClass '"\n}']);

            % Set the dimensions based on the full set of renderedData
            renderedDims = size(renderedData);
            this.DataModel.unpauseTimer();
        end

        function groupData = getRenderedGroupData(this)
            gd = getRenderedGroupData@internal.matlab.inspector.InspectorViewModel(this);
            groupData = cell(size(gd))';
            for idx = 1:length(gd)
                groupData{idx} = jsonencode(gd(idx));
            end
        end

        function dispatchErrorMessage(this, status, property)
            try
                % Send a status change and error message for the failure.
                % Include the oldValue (current rowData) for the property, for
                % potential use in undo/redo scenarios.
                [rowData, ~] = this.getRowDataForProperty(property);

                % Remove any hyperlinks from the message -- they link to matlab:
                % commands
                status = regexprep(status, '<.*?>', '');

                % Replace newlines with spaces.  The newlines look odd because they
                % break at widths applicable to the command line, but the inspector
                % width is much smaller
                status = strrep(status, newline, ' ');

                errStruct = struct(...
                    'type', 'dataChangeStatus', ...
                    'source', 'server', ...
                    'status', 'error', ...
                    'property', property, ...
                    'oldValue', jsonencode(rowData), ...
                    'message', status);
                if ~isempty(this.ErrorFcn)
                    % Call the ErrorFcn if it is set, and change the status to
                    % noChange, which will force an update of the client without
                    % actually showing the error message.
                    this.ErrorFcn(errStruct);
                    errStruct.status = 'noChange';
                end

                message.publish(this.MsgSvcChannel, errStruct);
            catch
                % Its possible the inspector is closing now, ignore errors
            end
        end

        function delete(this)
            % Delete the ViewModel.  Removes any listeners first.
            if ~isempty(this.propertyChangedListener)
                delete(this.propertyChangedListener);
            end

            if ~isempty(this.propertyAddedListener)
                delete(this.propertyAddedListener);
            end

            if ~isempty(this.propertyRemovedListener)
                delete(this.propertyRemovedListener);
            end

            if ~isempty(this.MetaDataChangedListener)
                delete(this.MetaDataChangedListener);
            end

            if ~isempty(this.PropMetadataChangedListener)
                delete(this.PropMetadataChangedListener);
            end
        end

        function eventData = getMetaDataChangedEventData(~, ed)
            eventData = struct(...
                'source', 'server', ...
                'type', 'metaDataChanged', ...
                'propertyName', 'objectBrowserMetaData', ...
                'newValue',  jsonencode(ed.Values));
        end

        function handleMetaDataChanged(this, ~, ed)
            message.publish(this.MsgSvcChannel, this.getMetaDataChangedEventData(ed));
        end

        function showObjectBrowser(this)
            % Send a message to the InspectorManager.js requesting it to
            % open the ObjectBrowser
            eventData = struct(...
                'source', 'server', ...
                'type', 'showObjectBrowser');
            message.publish(this.MsgSvcChannel, eventData );
        end

        function handlePropMetadataChanged(this, ~, ed, msgPublishFcn)
            arguments
                this
                ~
                ed
                msgPublishFcn = @message.publish
            end

            propertyName = ed.Properties;
            [rowData, editorProps] = this.getRowDataForProperty(propertyName);
            % Make sure the row for the property is found
            if ~isempty(rowData)
                eventData = struct(...
                    'source', 'server', ...
                    'type', 'propertyChanged', ...
                    'propertyName', propertyName, ...
                    'newValue', jsonencode(rowData));
                if isempty(editorProps)
                   editorProps = struct; 
                end
                editorProps.editable = (ed.Values.SetAccess == "public");
                editorProps.tooltip = ed.Values.DetailedDescription;
                eventData.state = jsonencode(editorProps);
                msgPublishFcn(this.MsgSvcChannel, eventData);
            end
        end

        function handleAutoRefreshChanged(this, ~, ed)
            eventData = struct(...
                'source', 'server', ...
                'type', 'autoRefreshChanged', ...
                'propertyName', 'autoRefreshChanged', ...
                'newValue',  jsonencode(ed.Values));

            message.publish(this.MsgSvcChannel, eventData);
        end

        function handlePropertyChanged(this, ~, ed)
            % Only one property changed at a time
            propertyName = ed.Properties;
            [rowData, editorProps] = this.getRowDataForProperty(propertyName);
            % Make sure the row for the property is found
            if ~isempty(rowData)
                eventData = struct(...
                    'source', 'server', ...
                    'type', 'propertyChanged', ...
                    'propertyName', propertyName, ...
                    'newValue', jsonencode(rowData));
                if ~isempty(editorProps)
                    % Add in any editor properties as well.  This could
                    % include, for example, the categories for a
                    % categorical variable.
                    eventData.state = jsonencode(editorProps);
                end
                message.publish(this.MsgSvcChannel, eventData);
            end
        end

        function handlePropertyAdded(this, ~, ed)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'propertyAdded', ...
                'property', ed.Properties));
        end

        function handlePropertyRemoved(this, ~, ed)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'propertyRemoved', ...
                'property', ed.Properties));
        end

        function handleFocusLost(this)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'focusLost'));
        end

        % Called to reset the object cache on the client which holds the state of
        % inspected objects (group expansion, scroll position, and alpha/grouped view
        function resetObjectCache(this)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'resetCache'));
        end

        function forceCloseInspector(this)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'closeInspector'));
        end

        % Called when an object selection changes.  When this happens we want to
        % notify the JS inspector client that this took place.
        function handleSelectChange(this)
            message.publish(this.MsgSvcChannel, struct(...
                'type', 'selectChange'));

            % Make sure the inspector timer is running.  We know that a new
            % object has been selected at this time, so it ought to be.
            this.DataModel.restartTimer();
        end

        % Override from PeerStructureViewModel because the Inspector doesn't use
        % the selection property, and it just causes extra processing
        function varargout = setSelection(~, varargin)
            varargout{1} = [];
        end

        function varargout = clientSetData(this, varargin)
            status = handleClientSetData(this, varargin{:});
            varargout = {status};
        end

        function varargout = handleActionEvent(this, ed)
            varargout{1} = 'noop';
            if ~isempty(this.ObjectActionCallback)
                try
                    % ObjectActionCallback can error out when
                    % performing any action. Send the error
                    % message to client in such cases.
                    this.ObjectActionCallback(ed, this.DataModel.MetaDataHandler);
                catch ex
                    varargout{1} = ex.message;
                    this.sendErrorMessage(ex.message);
                end
            end
        end
    end

    methods (Access = protected)

        function handleDataChangedOnDataModel(this, es ,ed)
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.StructureViewModel(es, ed);
        end

        function varargout = handleClientSetData(this, varargin)
            % Handles setData from the client and calls MCOS setData.  Also
            % fires a dataChangeStatus peerEvent.
            propertyName = this.getStructValue(varargin{1}, 'property');
            value = this.getStructValue(varargin{1}, 'value');
            if isjava(value)
                value = cell(value);
            elseif ischar(value) && any(strcmp(strtrim(value), this.RESTRICTED_COMMANDS))
                % Don't evaluate commands like exit.  Change this to the text instead, like 'exit'
                value = ['''' strtrim(value) ''''];
            end
            if isa(value, "char") || isa(value, "double")
                internal.matlab.datatoolsservices.logDebug("pi", "handleClientSetData: property = " + propertyName + ", value = " + value);
            else
                internal.matlab.datatoolsservices.logDebug("pi", "handleClientSetData: property = " + propertyName + ", value class = " + class(value));
            end

            currentValueFound = false;
            isOrigObjectProp = false;
            try
                % Retrieve current value for the property
                currentValue = this.DataModel.getData.getPropertyValue(propertyName);
                currentValueFound = true;
            catch
            end

            if ~currentValueFound
                try
                    currentValue = internal.matlab.inspector.PropertyAccessor.getValue(...
                        this.DataModel.getData.OriginalObjects(1), propertyName);
                    isOrigObjectProp = true;
                catch
                    % Just return if there's an error finding the original property.
                    % Its possible that the object being inspected changed since the
                    % setData call was made, so assume the user just switched
                    % objects and return.
                    varargout{1} = '';
                    return;
                end
            end

            w = warning('off', 'backtrace');
            revertWarning = onCleanup(@() warning(w));

            varargout{1} = '';
            try
                [dataType, isEnumeration] = this.getInspectedClassType(propertyName);

                % Check for empty value passed from user and replace with
                % valid "empty" value if current value is not an object or
                % is scalar datatype
                if isempty(value) && (isequal(dataType, 'any') || ...
                        contains(dataType, " ") || ...
                        any([internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes, ...
                        "struct", "table", "timetable", "cell", "datetime", ...
                        "duration", "calendarDuration", "char", "string", "categorical"] == dataType))

                    value = this.getInspectedEmptyValueReplacement(propertyName);
                    if ~ischar(value)
                        value = mat2str(value);
                    end
                else
                    % TODO: Code below does not test for expressions in
                    % terms of variables in the current workspace (e.g.
                    % "x(2)") and it allows expression in terms of local
                    % variables in this workspace. We need a better method
                    % for testing validity. LXE may provide this
                    % capability.
                    if ~ischar(value)
                        L = lasterror; %#ok<*LERR>
                        try
                            % If mat2str fails, it may be ok as the
                            % EditorConverter below may handle this
                            % class type
                            value = mat2str(value);
                        catch
                        end
                        lasterror(L);
                    end

                    widgetRegistry = internal.matlab.datatoolsservices.WidgetRegistry.getInstance;
                    widgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, dataType);
                    if isempty(widgets.EditorConverter)
                        if isEnumeration
                            widgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, ...
                                'categorical');
                        elseif isa(currentValue, 'function_handle')
                            widgets = widgetRegistry.getWidgets(this.WIDGET_REG_LOOKUP, ...
                                'function_handle');
                        end
                    end
                    if ~isempty(widgets.EditorConverter)
                        converter = eval(widgets.EditorConverter);

                        % Set the server value in order to get the editor state,
                        % which contains the dependent properties list
                        converter.setServerValue(currentValue, struct('Name', dataType), propertyName);
                        s = converter.getEditorState();

                        % Pass in data type and currentValue to the editor
                        % converter class.  (Don't use the struct function
                        % for currentValue because it has extra logic
                        % around handling empties/arrays that we don't want
                        % here).  Also include the values of the dependent
                        % properties as fields of the editor state struct.
                        currVal = struct('dataType', dataType);
                        currVal.currentValue = currentValue;
                        if ~isempty(s) && isfield(s, 'richEditorDependencies')
                            for i = 1:length(s.richEditorDependencies)
                                reProp = s.richEditorDependencies{i};
                                if isprop(this.DataModel.getData, reProp)
                                    currVal.(reProp) = this.DataModel.getData.getPropertyValue(reProp);
                                end
                            end
                        end

                        converter.setEditorState(currVal);

                        converter.setClientValue(value);

                        % Get the server value from the converter.  If it is
                        % text, make it valid for assignment using mat2str if it
                        % doesn't already have quotes.
                        value = converter.getServerValue();
                        if ischar(value)
                            isCellText = startsWith(value, '{') && endsWith(value, '}');
                            hasSingleQuotes = startsWith(value, '''') && endsWith(value, '''');
                            if ~isCellText && ~hasSingleQuotes
                                value = mat2str(value);
                            end
                        end
                    end

                    % Test for a valid expression. (assume cell arrays and
                    % any value which is not text will be valid)
                    if ischar(value) && ~isequal(strfind(value, '{'), 1)
                        result = this.getEvaledValue(value);
                        if ~this.validateInspectorInput(propertyName, result, currentValue)
                            this.dispatchErrorMessage(...
                                getString(message('MATLAB:codetools:variableeditor:InvalidInputType')), propertyName);
                            return;
                        end
                    end
                end

                if ischar(value)
                    % evaluate the text data sent from the client and break it
                    % apart as needed.  str2num properly handles comma separated
                    % and semi-colon separated numbers, so try this first
                    [eValue, status] = str2num(value);
                    if ~status
                        eValue = this.getEvaledValue(value);
                    end

                    if ~ischar(eValue)
                        if ~ischar(this.DataModel.Workspace) && ...
                                ismethod(this.DataModel.Workspace, 'disp')
                            try
                                dispValue = this.DataModel.Workspace.disp(value);
                            catch
                                dispValue = strtrim(evalc(...
                                    'evalin(this.DataModel.Workspace, [''disp('' value '')''])'));
                            end
                        else
                            dispValue = strtrim(evalc(...
                                'evalin(this.DataModel.Workspace, [''disp('' value '')''])'));
                        end
                    else
                        if contains(eValue, '*')
                            % The display value contains a scaling factor, like
                            % '1.03+04 *
                            % 2.5 1.18
                            % Use the original value instead (we know that its
                            % a char value already)
                            eValue = value;
                        end
                        containsBreaks = contains(eValue, newline);
                        hdr = strtrim(matlab.internal.display.getHeader({}));

                        % The eValue may contain hyperlink information, if
                        % hotlinks are enabled.  But (only?) under test
                        % situations can the evaluated value and the header
                        % have different hotlinks settings, so consider both
                        % with and without hotlinks for this comparison.
                        eValue2 = regexprep(eValue, '<[^>]*>', '');
                        if strcmp(eValue, hdr) || strcmp(eValue2, hdr)
                            % handle empty cell arrays
                            eValue = {};
                        elseif containsBreaks && startsWith(value, '{')
                            % This is a multi-line value, and should be treated
                            % as a cell array.  value will be something like:
                            % {'a';'b';'c'}, cellContents will be a 1x1 cell
                            % array, containing a 3x1 cell array like: {''a'';
                            % ''b'';''c''}, so just need to remove the extra
                            % quotes.
                            cellContents = textscan(value(2:end-1), '%q', ...
                                'Delimiter', ';', 'MultipleDelimsAsOne', true);
                            eValue = strrep(cellContents{1}, '''', '');
                        else
                            % The value is just a scalar char vector.  Eval it
                            % instead of using the result from the evalin
                            % this.DataModel.Workspace above, because we need
                            % the quotes to be removed.  For example, if
                            % value = '''test1'''; % 1x7 char array
                            % evalin(this.DataModel.Workspace, value) =
                            %     'test1' % 1x7 char array
                            % eval(value) = test1 % 1x5 char array
                            eValue = eval(value);
                        end

                        dispValue = value;
                    end
                else
                    % The value was retrieved from the convert above, just
                    % use it (no need to eval it)
                    eValue = value;
                    dispValue = '';
                end

                % Send data change event for equal data
                if isnumeric(eValue) && isnumeric(currentValue)
                    % use isSmallNumericChange to check if the value is the same.Because we want to ignore very small change in double.
                    noChange = internal.matlab.inspector.InspectorProxyMixin.isSmallNumericChange(eValue, currentValue);
                else
                    noChange = isequaln(eValue, currentValue);
                end
                if ~isequaln(class(currentValue), dataType) && ~strcmp(dataType, 'any')
                    L = lasterror; %#ok<*LERR>
                    try
                        noChange = isequaln(eValue, feval(dataType, currentValue));
                    catch
                    end
                    lasterror(L);
                end

                if noChange
                    [rowData, ~] = this.getRowDataForProperty(propertyName);
                    message.publish(this.MsgSvcChannel, struct(...
                        'type', 'dataChangeStatus', ...
                        'source', 'server', ...
                        'status', 'noChange', ...
                        'oldValue', jsonencode(rowData), ...
                        'property', propertyName));

                    % Even though the data has not changed we will fire a
                    % data changed event to take care of the case that the
                    % user has typed in a value that was to be evaluated in
                    % order to clear the expression and replace it with the
                    % value (e.g. pi with 3.1416)
                    eventdata = internal.matlab.variableeditor.DataChangeEventData;
                    eventdata.Range = [];
                    eventdata.Values = value;
                    this.notify('DataChange',eventdata);
                    return;
                end
                varargout{1} = '';
                if isEnumeration && ischar(eValue)
                    eValue = strrep(eValue, '''', '');
                    L = lasterror; %#ok<*LERR>
                    try
                        % Try to convert to actual enumeration if possible,
                        % but if not, just use the string representation
                        eValue = eval([dataType '.' eValue]);
                    catch
                    end
                    lasterror(L);
                end

                if isnumeric(eValue)
                    dispValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(eValue);
                end

                % Get the previous data -- but don't cache the values
                [oldValue, ~] = this.getRowDataForProperty(propertyName, false);
                if isKey(this.DataModel.getData.ObjRenderedData, propertyName)
                    remove(this.DataModel.getData.ObjRenderedData, propertyName);
                    remove(this.DataModel.getData.ObjectViewMap, propertyName);
                end

                % Defer to the command to update the Data Model
                if isOrigObjectProp
                    command = internal.matlab.inspector.InspectorUndoableCommand(...
                        this.DataModel.getData.OriginalObjects, propertyName, eValue, dispValue, this.DataModel.Name);
                else
                    command = internal.matlab.inspector.InspectorUndoableCommand(...
                        this.DataModel, propertyName, eValue, dispValue, this.DataModel.Name);
                end
                status = command.execute();

                if isempty(status)
                    % status = '' when there is no error
                    this.UndoQueue.addCommand(command);

                    % Executing the command above takes care of setting the
                    % new value on the object and ProxyView, but we still
                    % need to notify the DataModel of the change, so the
                    % client can be appropriately updated for any round
                    % trip updates
                    this.DataModel.flagDataChanged({propertyName});

                    [newValue, ~] = this.getRowDataForProperty(propertyName);

                    % oldValue and newValue are the full JSON data required by
                    % the property inspector.  So only if the values are really
                    % identical will there be 'noChange'
                    if isequal(oldValue, newValue)
                        setDataStatus = 'noChange';
                    else
                        setDataStatus = 'success';
                    end
                    message.publish(this.MsgSvcChannel, struct(...
                        'type', 'dataChangeStatus', ...
                        'source', 'server', ...
                        'status', setDataStatus, ...
                        'dispValue', dispValue, ...
                        'oldValue', jsonencode(oldValue), ...
                        'newValue', jsonencode(newValue), ...
                        'property', propertyName));

                    undoRedoEventData = internal.matlab.variableeditor.DataChangeEventData;
                    % Set the event to contain the required data
                    undoRedoData.command = command;
                    undoRedoEventData.Values = undoRedoData;
                    % This event is handled in PlotEditUndoRedoManager to
                    % perform undo/redo actions on figure property editing
                    %FIX - update listener for new event
                    this.notify('DataChange',undoRedoEventData);
                    ev = internal.matlab.inspector.PropertyEditedEventData;
                    ev.Property = propertyName;
                    ev.Object = command.EditedObject;
                    this.notify('PropertyEdited',ev)
                end
            catch e
                status = e.message;
                varargout{1} = status;
            end

            if ~isempty(status)
                this.dispatchErrorMessage(status, propertyName);
            end
        end

        function result = getEvaledValue(this, value)
            % Called to do an evalin of the value, in case the value is
            % something which can be eval'ed, like '1,2,3' or 'x' (where x is a
            % variable in the workspace)
            try
                % Try evalin in the Workspace object.  This is needed because it
                % has special handling of text like '1;2;3', which returns the
                % value as [1;2;3]  (this errors in the base workspace)
                result = evalin(this.DataModel.Workspace, value);
            catch
                % Try the evalin in the user's debug workspace, so if they have
                % typed a variable name, its value will be used.
                result = evalin("debug", value);
            end
        end

        function setupPagedDataHandler(~, ~)
            % This isn't used by the Property Inspector
        end

        function [propertySheetData, objectValueData, renderedDims] = renderData(this, ...
                ~, ~, ~, ~, propList)

            [psData, ovData] = renderDataStruct(this, propList);
            propertySheetData = cell(size(psData));
            objectValueData = cell(size(ovData));
            if ~isempty(propertySheetData)
                for idx = 1:length(psData)
                    propertySheetData{idx} = jsonencode(psData(idx));
                    objectValueData{idx} = ['"' psData(idx).name '": '...
                        jsonencode(ovData(idx))];
                end
            end

            renderedDims = size(propertySheetData);
        end

        function dispatchSetDataEvent(this, startRow, endRow, startColumn, endColumn, renderedData)
            % Dispatch a peer event with the renderedData
            renderedDims = size(renderedData);
            message.publish(this.MsgSvcChannel, struct('type', 'setData', ...
                'source', 'server', ...
                'startRow', startRow-1, ...
                'endRow', endRow-1, ...
                'startColumn', startColumn-1, ...
                'endColumn', endColumn-1, ...
                'data', {renderedData}, ...
                'rowCount', renderedDims(1), ...
                'columnCount', renderedDims(2)));
            message.publish(this.MsgSvcChannel, struct('type', 'setData', 'data', strjoin(renderedData)));
        end

        % Override from PeerStructureViewModel because the Inspector doesn't use
        % the selected fields property, and it just causes extra processing
        function updateSelectedFields(~)
        end

        % Override from PeerStructureViewModel because the Inspector doesn't use
        % the selected row intervals property, and it just causes extra
        % processing
        function updateSelectedRowIntervals(~)
        end

        function initializePlugins(~)
        end

        function [renderedData, idx] = addInObjectBrowserData(this, renderedData, idx)
            mData = this.DataModel.MetaDataHandler.getData();
            % Add breadcrumbs data conditionally - only for valid (parented) graphics
            % objects
            if ~isempty(mData.breadCrumbsData)
                idx = idx + 1;
                renderedData{idx,1} = sprintf('\t"breadCrumbsData":[\n');
                idx = idx + 1;
                internal.matlab.datatoolsservices.logDebug("pi", "Breadcrumbs length: " + numel(mData.breadCrumbsData));
                for i = 1:numel(mData.breadCrumbsData)
                    if (i>1)
                        renderedData{idx-1,1} = [renderedData{idx-1,1} ','];
                    end
                    renderedData{idx,1} = mData.breadCrumbsData{i};
                    idx = idx + 1;
                end
                renderedData{idx,1} = sprintf('\t\t],\n');
                idx = idx + 1;
            end

            % Add tree data conditionally - only for valid (parented) graphics
            % objects
            if ~isempty(mData.treeData)
                renderedData{idx,1} = sprintf('\t"treeData":[\n');
                idx = idx + 1;
                internal.matlab.datatoolsservices.logDebug("pi", "TreeData length: " + numel(mData.treeData));
                for i = 1:numel(mData.treeData)
                    if (i>1)
                        renderedData{idx-1,1} = [renderedData{idx-1,1} ','];
                    end
                    renderedData{idx,1} = mData.treeData{i};
                    idx = idx + 1;
                end
                renderedData{idx,1} = sprintf('\t\t],\n');
            end
        end
    end

    methods(Static, Hidden)
        function b = useDataFromCacheForObj(inspectedObj)
            b = true;

            % Use the data from the cache, unless this is an Axes object with
            % non-numeric data.  Axes is unique in that many of its editors swap
            % out for non-numeric data, but the cache was created with numeric
            % data.
            if isa(inspectedObj, "matlab.graphics.axis.Axes")
                if ~isscalar(inspectedObj)
                    b = false;
                elseif ~isnumeric(inspectedObj.XTick) || ~isnumeric(inspectedObj.YTick) || ~isnumeric(inspectedObj.ZTick)
                    b = false;
                end
            end
        end
    end
end


