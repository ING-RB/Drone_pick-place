classdef RemoteDocument < internal.matlab.variableeditor.MLDocument
    % REMOTEDOCUMENT Document on the server
    % Responds and updates itself when its corresponding variable changes

    % Copyright 2019-2025 The MathWorks, Inc.

    properties
        DocID;
    end

    properties (Transient)
        Provider;
    end

    properties(Access=protected, Transient)
        DataModelChangeListener
    end

    events
        DoubleClickOnVariable;
    end

    methods
        % Constructor
        function this = RemoteDocument(provider, manager, adaptor, docID, documentArgs)
            arguments
                provider
                manager
                adaptor
                docID char
                documentArgs.UserContext char = '';
                documentArgs.DisplayFormat = '';
            end
            args = namedargs2cell(documentArgs);
            this = this@internal.matlab.variableeditor.MLDocument(manager, adaptor, args{:});
            this.Provider = provider;
            this.DocID = docID;

            documentInfo = getDocumentInfo(this, manager, adaptor, documentArgs.UserContext, docID);
            this.Provider.addDocument(this.DocID, documentInfo);
            this.Provider.setUpProviderListeners(this, this.DocID);

            this.DataModel = adaptor.getDataModel();
            this.ViewModel = adaptor.getViewModel(this);

            this.DataModelChangeListener = addlistener(this.DataModel, 'DataChange', @(e,d)this.updateStatusInfo);
        end

        function documentInfo = getDocumentInfo(this, manager, variable, userContext, docID)
            % Call into getCloneData so we get the underlying datatype.
            % This returns DataModel's Data and timetable data in case of timetables.
            vardata = (variable.getDataModel.getCloneData);

            [secondaryType, secondaryStatus, rawData] = this.getVariableSecondaryInfo();

            % Pass in container Type to the client side as this is used to
            % query the registry for the type of view added to the document
            [varType, containerType] = internal.matlab.variableeditor.peer.RemoteDocument.resolveTypeWithDataModel(vardata, variable);

            % get DataAttributes for the variable
            validAttributesJSON = internal.matlab.variableeditor.peer.RemoteDocument.getDataAttributesJSON(rawData);

            documentInfo = struct;
            documentInfo.name = variable.Name;
            documentInfo.type = varType;
            documentInfo.containerType = containerType;
            documentInfo.displaySize = variable.ViewModel.getDisplaySize();
            documentInfo.size = variable.ViewModel.getSize();
            documentInfo.secondaryType = secondaryType;
            documentInfo.secondaryStatus = secondaryStatus;
            documentInfo.workspace = manager.getWorkspaceKey(variable.getDataModel.Workspace);
            documentInfo.docID = docID;
            documentInfo.userContext = userContext;
            documentInfo.dataAttributes = validAttributesJSON;
            parentName = internal.matlab.variableeditor.Document.getParentName(documentInfo.name);
            if ~isempty(parentName)
                documentInfo.parentName = parentName;
            else
                parentName = "";
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::getDocumentInfo",...
                "name: " + documentInfo.name + ...
                "  type: " + documentInfo.type + ...
                "  containerType: " + documentInfo.containerType + ...
                "  displaySize: " + documentInfo.displaySize + ...
                "  size: " + strjoin(string(documentInfo.size), ",") + ...
                "  secondaryType: " + documentInfo.secondaryType + ...
                "  secondaryStatus: " + documentInfo.secondaryStatus + ...
                "  workspace: " + documentInfo.workspace + ...
                "  docID: " + documentInfo.docID + ...
                "  userContext: " + documentInfo.userContext + ...
                "  dataAttributes: " + validAttributesJSON + ...
                "  parentName: " + parentName ...
                );
        end

        function [secondaryType, secondaryStatus, data] = getVariableSecondaryInfo(this, data)
            if nargin < 2
                if isprop(this.DataModel, 'DataI')
                    data = this.DataModel.DataI;
                else
                    data = this.DataModel.getCloneData;
                end
            end
            [secondaryType, secondaryStatus] = ...
                internal.matlab.datatoolsservices.FormatDataUtils.getVariableSecondaryInfo(data);

            % TODO: Refactor out of document
            if ~ismatrix(data) && isprop(this.DataModel, 'Slice')
                secondaryStatus = "(" + strjoin(this.DataModel.Slice," , ") + ")";
            end

            if ismethod(this.ViewModel, 'getSecondaryStatus')
                secondaryStatus = this.ViewModel.getSecondaryStatus();
            end
        end

        function updateStatusInfo(this)
            [secondaryType, secondaryStatus] = this.getVariableSecondaryInfo();

            this.setProperty('secondaryType', secondaryType);
            this.setProperty('secondaryStatus', secondaryStatus);
        end

        function data = variableChanged(this, options)
            arguments
                this
                options.newData = [];
                options.newSize = 0;
                options.newClass = '';
                options.eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
            end

            import internal.matlab.datatoolsservices.FormatDataUtils;
            % varargin{1} : changed data for the variable
            % varargin{2} : size of the variable, has to be formatted to
            % display in MOL(n-D types are to be displayed appropriately.
            % varargin{3} : type of variable, has to be formatted to
            % consider complex/sparse and other types.

            newData = options.newData;
            newSize = options.newSize;
            newClass = options.newClass;

            [~,newContainerType, modifiedVarSize] = internal.matlab.variableeditor.peer.RemoteDocument.resolveType(...
                newData);
            % If type is set as empty, this means this was fired from the
            % catch block after an unsuccessful eval, show this in
            % unsupported view.
            if (isempty(newClass))
                newContainerType = '';
            end

            % If we currently are a numeric object container and this data is
            % still a numeric object, we want to continue to map this to
            % an object container g3217430
            isObjectTypeContainer = internal.matlab.variableeditor.Document.isObjectTypeContainer(this.ViewModel, newData);
            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::variableChanged", "isObjectTypeContainer: " + isObjectTypeContainer);
            if isObjectTypeContainer
                newContainerType = 'object';
            end

            displaySize = newSize;

            % If modifiedVarSize is returned by resolveType, use that to be the newSize.
            if ~isempty(modifiedVarSize) && ~isempty(newContainerType)
                newSize = modifiedVarSize;
            end

            tallVar = isa(newData, 'tall');
            if tallVar || numel(newSize) > 1
                displaySize = internal.matlab.datatoolsservices.FormatDataUtils.formatSize(newData, false);
                % TODO: Move PeerUtils usages to a RemoteUtils
                newClass = internal.matlab.variableeditor.peer.PeerUtils.formatClass(newData);
            end
            % TODO: Bunch all these property updates in one event.
            this.setProperty('name', this.Name);
            this.setProperty('size', newSize);
            this.setProperty('displaySize', displaySize);
            this.setProperty('type', newClass);
            this.setProperty('containerType', newContainerType);
            validAttributesJSON = internal.matlab.variableeditor.peer.RemoteDocument.getDataAttributesJSON(newData);
            this.setProperty('dataAttributes', validAttributesJSON);
            [secondaryType, secondaryStatus] = this.getVariableSecondaryInfo(newData);

            this.setProperty('secondaryType', secondaryType);
            this.setProperty('secondaryStatus', secondaryStatus);
            parentName = internal.matlab.variableeditor.Document.getParentName(this.DataModel.Name);
            if ~isempty(parentName)
                this.setProperty('parentName', parentName);
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::variableChanged",...
                "name: " + this.Name + ...
                "  type: " + newClass + ...
                "  containerType: " + newContainerType + ...
                "  secondaryType: " + secondaryType + ...
                "  secondaryStatus: " + secondaryStatus + ...
                "  docID: " + this.DocID + ...
                "  dataAttributes: " + validAttributesJSON ...
                );


            
            if ~isempty(this.Provider)
                % Ensure that we set document properties before we publish
                % variableChanged. The client will know the correct
                % containerType on view change.
                data = this.variableChanged@internal.matlab.variableeditor.MLDocument(...
                    newData = options.newData, newSize = options.newSize, newClass = options.newClass, eventType = options.eventType);
                % Update the change listener in cases the data model
                % changed
                if ~isempty(this.DataModelChangeListener)
                    delete(this.DataModelChangeListener);
                end
                this.DataModelChangeListener = addlistener(this.DataModel, 'DataChange', @(e,d)this.updateStatusInfo);

                this.updateStatusInfo();
            end
        end

        function storedValue = get.DocID(this)
            storedValue = this.DocID;
        end

        % Calls into the provider to set a property on the client
        function setProperty(this, propertyName, propertyValue)
            if ~isempty(this.Provider)
                try
                    this.Provider.setPropertyOnClient(propertyName, propertyValue, this, this.DocID);
                catch
                    % This has only been seen in testing.  Ignore the failure, but log it.
                    internal.matlab.datatoolsservices.logDebug("variableeditor::remoteDocument", "failure setting property");
                end
            end
        end

        % Returns the property value of the given property by accessing the
        % provider
        function propertyValue = getProperty(this, propertyName)
            propertyValue = this.Provider.getProperty(propertyName, this, this.DocID);
        end

        function handlePropertySetFromClient(~, ~, ~)
        end

        function handleEventFromClient(this, ~, eventData)
           if strcmp(eventData.data.type, 'doubleClickedOnMetaData')
                ed = internal.matlab.variableeditor.OpenVariableEventData;
                % Ensure row and column are 1 indexed
                ed.row = eventData.data.row + 1;
                ed.column = eventData.data.column + 1;
                ed.workspace = eventData.data.workspace;
                ed.variableName = eventData.data.variableName;
                ed.parentName = eventData.data.parentName;
                this.notify('DoubleClickOnVariable', ed);
           end
        end

        % Returns true of the adapter is of type
        % RemoteObject/RemoteObjectArray
        function isObjType = isObjectTypeAdapter(~, adapterClass)
            isObjType = any(strcmp(adapterClass, {'internal.matlab.variableeditor.peer.RemoteObjectAdapter', ...
                'internal.matlab.variableeditor.peer.RemoteObjectArrayAdapter'}));
        end

        function delete(this)
            % isvalid check since the delete on RemoteManager triggers the
            % delete on Provider and subsequently the document nodes.
            % The MLManager's delete calls into the delete of the document
            % itself but at this point the Provider and the map have
            % already been cleaned up.
            if ~isempty(this.Provider) && isvalid(this.Provider)
                this.Provider.deleteDocument(this.DocID);
            end
            if ~isempty(this.DataModelChangeListener)
                delete(this.DataModelChangeListener);
            end
        end
    end

    methods(Static = true)
        % For any datamodel/viewmodel specific comparisons, resolveType to
        % ensure that we send the right containerType across.
        function [vartype, containerType] = resolveTypeWithDataModel(vardata, variable)
            dm = variable.getDataModel;
            vm = variable.ViewModel;
            [vartype, containerType] = internal.matlab.variableeditor.peer.RemoteDocument.resolveType(vardata);
            if (strcmp(dm.Type, internal.matlab.variableeditor.MLUnsupportedDataModel.Type))
                containerType = '';
            elseif (strcmp(dm.Type, internal.matlab.variableeditor.MLCustomDisplayDataModel.Type))
                containerType = internal.matlab.variableeditor.MLCustomDisplayDataModel.Type;
                vartype = containerType;
            elseif internal.matlab.variableeditor.Document.isObjectTypeContainer(vm, vardata)
                containerType = 'object';
            elseif (strcmp(dm.Type, internal.matlab.variableeditor.MLOptimvarDataModel.Type))
                containerType = 'optimvar';
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::resolveTypeWithDataModel", "vartype: " + vartype + "  containerType: " + containerType);
        end

        % Resolve cases where the variable data may be recognized as a different
        % type/size.  For example, empty char being recognized as double.  In cases like
        % this, use the DataModel type.
        % If size was recognized differently, return modifiedSize, else
        % just return [];
        function [vartype, containerType, modifiedVarSize] = resolveType(vardata)
            vartype = internal.matlab.variableeditor.peer.PeerUtils.formatClass(vardata);
            containerType = internal.matlab.variableeditor.Document.getContainerType(vardata);
            modifiedVarSize = [];
            % We only support scalar chars,Check if this is a supported
            % char type and set dimensions/containerType accordingly.
            if strcmp(vartype, 'char')
                s = size(vardata);
                if (length(s) == 2 && s(1) <= 1 && s(2) <= internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH)
                    vartype = 'char';
                    containerType = vartype;
                    modifiedVarSize = [1,1];
                end
            elseif (internal.matlab.variableeditor.MLManager.isSupportedOptimvarType(vardata))
                containerType = 'optimvar';
            end
            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::resolveType", "vartype: " + vartype + "  containerType: " + containerType);
        end

        % Looks into varData and gets DataAttributes for the given data.
        function attributesJSON = getDataAttributesJSON(vardata)
            varSize = internal.matlab.datatoolsservices.FormatDataUtils.getVariableSize(vardata);
            veDataAttributes = internal.matlab.variableeditor.VEDataAttributes(vardata, varSize);
            [~, validAttributes] = internal.matlab.datatoolsservices.WidgetRegistry.getDataAttributes(veDataAttributes, varSize);
            attributesJSON = internal.matlab.variableeditor.peer.PeerUtils.toJSON(false, validAttributes);

            try
                internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDocument::getDataAttributesJSON", "  varSize: " + strjoin(string(varSize), ",") + "  attributesJSON: " + attributesJSON);
            catch % g3346715: Logging will fail when "varSize" contains a NaN (since NaN cannot be converted to a string); we silently fail in this case.
            end
        end
    end
end
