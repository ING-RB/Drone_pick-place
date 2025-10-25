classdef MLDocument < internal.matlab.variableeditor.Document & internal.matlab.variableeditor.MLNamedVariableObserver
    % MLDocument is a document class in a particular workspace. All
    % workspace related updates are subscribed to and Document is updated.

    % Copyright 2013-2024 The MathWorks, Inc.

    properties
        PreviousFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
    end
    
    % ViewModel
    properties (SetAccess='protected', GetAccess='public', Dependent=false, Hidden=true)
        CurrentAdapterName (1,1) string = "";
        CurrentAdapterClassName (1,1) string = "";
    end

    properties(Access='protected', Transient)
        DeletionListener=[];
        NameChangedListener = [];
    end
    
    methods(Access='protected')
        % When a document undergoes a name change, update the underlying
        % DataModel as well.
        function handleNameChanged(this)
            % Manager makes an assumption that if ignoreUpdates is true,
            % varName will be the docID, do not update DataModel for these
            % cases.
            if ~this.IgnoreUpdates
                this.DataModel.Name = this.Name;
            end
        end
    end

    methods
        %   MLDocument() creates a Document class and adds workspace
        %   listeners through the observer
        %   'manager'        manager obj passed on to document.      
        %   'variable'       adaptor for the document that creates the
        %                    right DataModel and ViewModel for the workspace variable.
        %   'UserContext'    Optional Context in which the variable is to be opened. For e.g 'MOTW' | 'liveeditor'
        %   'DisplayFormat'  Optional DisplayFormat when provided, the
        %                    numberic data in the variable will be displayed with this
        %                    number display format.
        function this = MLDocument(manager, variable, documentArgs)
            arguments
                manager
                variable
                documentArgs.UserContext char = '';
                documentArgs.DisplayFormat char = '';
            end
            dm = variable.DataModel;
            args = namedargs2cell(documentArgs);
            this@internal.matlab.variableeditor.Document(manager, dm, variable.ViewModel, args{:});
            this@internal.matlab.variableeditor.MLNamedVariableObserver(variable.Name, dm.Workspace);
            this.CurrentAdapterName = class(variable);
            data = dm.Data;
            this.CurrentAdapterClassName = internal.matlab.variableeditor.MLManager.getVariableAdapterClassTypeHelper(class(data), char(this.CurrentAdapterName));
            try
                if isa(data, 'handle') && ~isempty(data) && ismethod(data, 'isvalid') && any(any(isvalid(data)))
                    this.addDeletionListener(data);
                end
            catch
            end
            % Whenver 'Name' is set on the document, call
            % handleNameChanged in order to update the DataModel.
            this.NameChangedListener = event.proplistener(this, ...
                    this.findprop('Name'), 'PostSet', @(es, ed) this.handleNameChanged());
        end
        
        function data = variableChanged(this, options)
            arguments
                this
            	options.newData = [];
            	options.newSize = 0;
            	options.newClass = '';
            	options.eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
            end

            % Check data type and see if we need to create new models
            newData = options.newData;
            newSize = options.newSize;
            newClass = options.newClass;
			
            % Check for type changes
            oldData = this.DataModel.getCloneData;
            
            adapter = [];
            dimsChanged = false;
            if (isa(newData, 'internal.matlab.variableeditor.VariableEditorMixin'))
                if (~strcmp(class(this.DataModel),class(newData.getDataModel())) || ...
                    ~strcmp(class(this.ViewModel),class(newData.getViewModel())))
                 %Check to see if we have a new type of VariableEditorMixIn
                adapter = newData;
                end
            else
                % Check to see if either the number of dimensions (i.e. we've
                % changed from a scalar to a matrix or multidimensional array)
                % or if the type has changed
                % we need to check the class type of new data using the new adapter since in some cases
                % (like char arrays), class(newData) is not the same as newAdapter.getDataModel(this).getClassType()
                dimsChanged = this.isDimsChanged(oldData, ...
                    newData);
                isUnsupported = any(strcmp(this.DataModel.getClassType(), 'unsupported'));

                %Get the current adapter and the new adapter names and
                %compare them. Swap the old one only if they are different
                currAdapterName = this.CurrentAdapterName;
                newAdapterName = this.Manager.getAdapterClassNameForData(newClass, newSize, newData, this.UserContext);

                internal.matlab.datatoolsservices.logDebug("variableeditor::MLDocument::adapaters", "old apater: " + currAdapterName + "   new adapter: " + newAdapterName);

                % get the new adapter class name(s), and make sure its a
                % cell array
                newAdapterClass = this.Manager.getVariableAdapterClassType(...
                    newClass, newSize, newData);
                if ~iscell(newAdapterClass) 
                    newAdapterClass = {newAdapterClass};
                end
                currAdapterClass = this.CurrentAdapterClassName;

                internal.matlab.datatoolsservices.logDebug("variableeditor::MLDocument::classees", "old apater class: " + currAdapterClass + "   new adapter class: " + newAdapterClass);

                % Save new adapters
                this.CurrentAdapterName = newAdapterName;
                this.CurrentAdapterClassName = newAdapterClass;


                % In certain cases where we get redundant updates (like
                % ans), we want to make sure that if newAdapter is our
                % ObjectAdapter, then we set containerType accordingly
                if ~isempty(newAdapterName) && this.isObjectTypeAdapter(newAdapterName)
                    this.setProperty('containerType', 'object');
                end
                
                % Check to see if this was a change of workspace event.  If
                % so, we need to redisplay because it is possible the
                % display has changed (for objects)
                wsChange = any(options.eventType == [...
                    internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CHANGED, ...
                    internal.matlab.datatoolsservices.WorkspaceEventType.CHANGE_CURR_WORKSPACE]);

                if (dimsChanged && ~strcmp(currAdapterName, newAdapterName)) || ...
                        ~ismember(currAdapterClass, newAdapterClass) || ...
                        isUnsupported
                    adapter = this.Manager.getVariableAdapter(...
                        this.Name, this.Workspace, newClass, ...
                        newSize, newData, this.UserContext);
                elseif isobject(newData) && ((isa(newData, 'handle') && ...
                        all(size(newData) >= [1, 1]) && ...
                        ~any(any(isvalid(newData)))) || wsChange)
                    adapter = this.Manager.getVariableAdapter(...
                        this.Name, this.Workspace, newClass, ...
                        newSize, newData, this.UserContext);
                    %add and remove deletion listeners as appropriate
                    this.checkDeletionListeners(newData, oldData);
                end
            end

            if ~isempty(adapter)
                % Based on New ViewModel and New DataModel, if
                % containertype changes, setProperty to new type before new vm is created.                
                vm = adapter.ViewModel;
                if internal.matlab.variableeditor.Document.isObjectTypeContainer(vm, newData)
                    this.setProperty('containerType', 'object');
                elseif (strcmp(adapter.DataModel.Type, 'Unsupported'))
                    this.setProperty('containerType', '');
                end
                
                classTypeChange = ~any(strcmp(this.DataModel.getClassType(), ...
                    adapter.getDataModel(this).getClassType()));
                dataChanged = ~internal.matlab.variableeditor.areVariablesEqual(...
                    this.DataModel.getCloneData, adapter.getDataModel(this).getCloneData);
            end

            % Fire a change event if there is a change in class type, or if
            % it is unsupported, but the data has changed
            if ~isempty(adapter) && ...
                    (((classTypeChange || dimsChanged || wsChange) && ~this.IgnoreScopeChange) || ...
                    (isUnsupported && dataChanged))
                internal.matlab.datatoolsservices.logDebug("variableeditor::MLDocument", "variablechanged:Detected View Change");

                % We need to swap out the data and view models
%                 if iscell(this.ViewModel)
%                     % delete all the ViewModels
%                     for k = 1:length(this.ViewModel)
%                         delete(this.ViewModel(k));
%                     end
%                     this.ViewModel = [];
%                 else
%                 end
                for i=1:length(this.ViewModels)
                    delete(this.ViewModels(i));
                end
                                
                delete(this.DataModel);
                this.removeDeletionListener();
                newDataModel = adapter.getDataModel(this);
                newViewModel = adapter.getViewModel(this);
                
                this.DataModel = newDataModel;
                % create the default/primary view model using the view
                % returned by the adapter
                this.ViewModels = newViewModel;                
                
                % Fire DocumentTypeChanged Event
                eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
                eventdata.Name = this.Name;
                eventdata.Workspace = this.Workspace;
                eventdata.Document = this;
                this.notify('DocumentTypeChanged', eventdata);
            else
                % If the global format has changed force a refresh
                % TODO: remove this once ViewModel level formatting is
                % implemented
                currFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
                if ~strcmp(this.PreviousFormat, currFormat)
                    ed = internal.matlab.datatoolsservices.data.DataChangeEventData;
                    % Force a refresh of the entire dataSize, this will
                    % cause buffers to get cleared on the client side.
                    dataSize = this.DataModel.getSize();
                    ed.StartRow = 1;
                    ed.EndRow = dataSize(1);
                    ed.StartColumn = 1;
                    ed.EndColumn = dataSize(2);
                    this.ViewModel.notify('DataChange', ed);
                    this.PreviousFormat = currFormat;
                end
            end

            data = this.DataModel.getCloneData();
        end
        
        function delete(this)
            if ~isempty(this.Manager) && isvalid(this.Manager)
                this.Manager.closevar(this.Name, this.Workspace);
            end
        end
        
        function name = getVariableName(this)
            name = this.Name;
        end
        
        function ws = getVariableWorkspace(this)
            ws = this.Workspace;
        end
        
        function [] = checkDeletionListeners(this, newData, oldData)
            if isa(oldData, 'handle') && any(any(isvalid(oldData)))
                % old data is valid handle
                if ~isequaln(oldData, newData)
                    % and new data is not exact same handle then remove
                    % current listener on old object
                    this.removeDeletionListener();

                    if isa(newData, 'handle') && any(any(isvalid(newData)))
                        % and if new data is a valid handle then add new
                        % deletionlistener
                        this.addDeletionListener(newData);
                    end
                end
            else
                % old data is not a valid handle
                if isa(newData, 'handle') && any(any(isvalid(newData)))
                    % if new data is a valid handle then add new
                    % deletionlistener
                    this.addDeletionListener(newData);
                end
            end
        end
        
        function [] = addDeletionListener(this, obj)
            if ~isempty(this.DeletionListener)
                this.removeDeletionListener();
            end
           
            this.DeletionListener = event.listener(obj, 'ObjectBeingDestroyed', @this.deletionCallback);
        end
        
        function [] = removeDeletionListener(this)
            delete(this.DeletionListener);
            this.DeletionListener=[];
        end
        
        function [] = deletionCallback(this, varargin)
            if this.DataModel.isvalid
                data=this.DataModel.Data;
                
                %call the variableChanged function on same variable
                
                %if variable has been deleted, this will change the variable
                %type to unsupported and display the appropriate error message
                this.variableChanged(newData = data, newSize = size(data), newClass = class(data));
            end
        end
        
        function dimsChanged = isDimsChanged(~, oldData, newData)
            % dimsChanged is true if the dimensions of the data have
            % changed
            if istall(oldData) || istall(newData)
                % Special handling for tall variables.  The size of a tall
                % variable is a tall variable, so use the getArrayInfo to
                % try to compare sizes.
                if istall(oldData) && istall(newData)
                    oldTallInfo = matlab.bigdata.internal.util.getArrayInfo(oldData);
                    newTallInfo = matlab.bigdata.internal.util.getArrayInfo(newData);
                    dimsChanged = ~isequaln(oldTallInfo.Size, newTallInfo.Size);
                else
                    % The variable was tall and is no longer, or vice
                    % versa.  Consider this a dimension change.
                    dimsChanged = true;
                end
            else
                dimsChanged = ~isequal(length(size(oldData)),length(size(newData)));
                
                % in some cases (like structure arrays) the change in
                % dimensions is not represented in the length of the size of
                % data
                % explicitly check if scalar data has changed to vector and
                % vice versa
                if ~dimsChanged
                    oldDataScalar = isscalar(oldData);
                    newDataScalar = isscalar(newData);
                    isequalData = isequal(size(oldData), size(newData));
                    
                    if (oldDataScalar && ~newDataScalar) || (newDataScalar && ~oldDataScalar) ...
                            || (~isequalData)
                        dimsChanged = true;
                    end
                end
            end
        end
    end
end

