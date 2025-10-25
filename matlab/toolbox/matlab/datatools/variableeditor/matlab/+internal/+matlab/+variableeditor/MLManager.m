classdef MLManager < internal.matlab.variableeditor.Manager
    % A class defining MATLAB Variable Manager
    %

    % Copyright 2013-2025 The MathWorks, Inc.

    % Workspaces
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % Workspaces Property
        Workspaces = containers.Map;
        WorkspaceCounts = containers.Map;

        % RegisteredWorkspaces Property
        RegisteredWorkspaces = containers.Map;
    end %properties

    properties
        IgnoreUpdates = false;
    end

    properties(Constant, Hidden)
        TABLE_COLUMNS_LIMIT = inf; % no need for a limit since data is paged in, this is a break from the old Java behavior
        ACTION_WORKSPACES = {'filterWorkspace'};
        MAIN_VE_USER_CONTEXT = 'MOTW';
        UIVARIABLEEDITOR_CONTEXT = 'UIVariableEditor';
    end

    methods(Access='protected')
        % Persistent method to retrieve the next workspace counter value
        % the update flag specifies whether to increment the value
        function wsc = getWorkspaceCounter(~, update)
            mlock;
            persistent workspaceCounter;
            if isempty(workspaceCounter)
                workspaceCounter = 0;
            end

            if nargin < 2
                update = false;
            end

            if update
                workspaceCounter = workspaceCounter + 1;
            end

            wsc = workspaceCounter;
        end

        % Adds a workspace to the managers workspace hash, if a key has not
        % already been created for the workspace one will be generated
        function key = addWorkspace(this, workspace)
            key = this.getWorkspaceKey(workspace);

            if isempty(key)
                workspaceCounter = this.getWorkspaceCounter(true);
                key = ['workspace_' num2str(workspaceCounter)];
            end

            if ~this.Workspaces.isKey(key)
                this.Workspaces(key) = workspace;
            end
        end

        % Does a check to see if any of the open documents belong to the
        % workspace passed in.
        function foundWorkspace = workspaceHasOpenDocuments(this, workspace)
            foundWorkspace = false;
            wsKey = this.getWorkspaceKey(workspace);

            if ~isempty(this.Documents) && ...
                    any(isvalid(this.Documents)) && ...
                    this.WorkspaceCounts.isKey(wsKey)
                foundWorkspace = this.WorkspaceCounts(wsKey) >= 1;
            end
        end

        % This removes any workspaces from the workspace hash that do not
        % have open documents.
        function cleanupWorkspace(this, workspace, wsKey)
            % If this is not a user registered workspace check to see if it
            % should be removed (i.e. no open documents)
            if ~this.workspaceHasOpenDocuments(workspace) &&...
                    ~this.RegisteredWorkspaces.isKey(wsKey)
                this.removeWorkspace(workspace);
            end
        end

        % Removed a workspace from the managers workspace hash
        function key = removeWorkspace(this, workspace)
            key = this.getWorkspaceKey(workspace);

            if isempty(key)
                workspaceCounter = this.getWorkspaceCounter(true);
                key = ['workspace_' num2str(workspaceCounter)];
            end

            if this.Workspaces.isKey(key) && ...
                ~this.workspaceHasOpenDocuments(workspace) &&...
                    ~this.RegisteredWorkspaces.isKey(key)
                this.Workspaces.remove(key);
                if this.WorkspaceCounts.isKey(key)
                    this.WorkspaceCounts.remove(key);
                end
            end
        end

        % Gets the workspace associated with the given key.  If the
        % workspace isn't already in the workspace hash it will be added.
        function workspace = getWorkspace(this, workspaceKey)
            workspace = workspaceKey;
            if ischar(workspace)
                if ~this.Workspaces.isKey(workspaceKey)
                    this.addWorkspace(workspaceKey);
                end
                workspace = this.Workspaces(workspaceKey);
            else
                if isempty(this.getWorkspaceKey(workspaceKey))
                    this.addWorkspace(workspaceKey);
                end
            end
        end

        function varDocument = addDocument(this, veVar, userContext, displayFormat)
            varDocument = [];
            if ~isempty(veVar)
                varDocument = internal.matlab.variableeditor.MLDocument(this, veVar, UserContext=userContext, DisplayFormat=displayFormat);
                varDocument.IgnoreUpdates = this.IgnoreUpdates;
                varDocument.DataModel.IgnoreUpdates = this.IgnoreUpdates;

                this.Documents = [this.Documents varDocument];

                % Increment the workspace document counter
                this.incrementWorkspaceDocCount(veVar.DataModel.Workspace);
            end
        end

        function incrementWorkspaceDocCount(this, workspace)
            % Add to workspace counts
            wsKey = this.getWorkspaceKey(workspace);
            if ~this.WorkspaceCounts.isKey(wsKey)
                this.WorkspaceCounts(wsKey) = 1;
            else
                this.WorkspaceCounts(wsKey) = this.WorkspaceCounts(wsKey) + 1;
            end
        end

        function deccrementWorkspaceDocCount(this, workspace)
            % Add to workspace counts
            wsKey = this.getWorkspaceKey(workspace);
            if this.WorkspaceCounts.isKey(wsKey)
                if this.WorkspaceCounts(wsKey) > 1
                   this.WorkspaceCounts(wsKey) = this.WorkspaceCounts(wsKey) - 1;
                else
                    this.WorkspaceCounts.remove(wsKey);
                end
            end
        end

        function removeDocument(this, name, workspace)
            docIndex = this.documentIndex(name, workspace);
            if ~isempty(docIndex)
                if this.FocusedDocument == this.Documents(docIndex)
                    this.FocusedDocument = [];
                end

                doc = this.Documents(docIndex);
                % Delete the document
                if isvalid(doc)
                    delete(doc);
                end

                % Remove the element from the Documents list
                if ~isempty(this.Documents) && ...
                        docIndex <= length(this.Documents) && ...
                        isequal(this.Documents(docIndex), doc)
                    this.Documents = [this.Documents(1:docIndex-1) this.Documents(docIndex+1:end)];
                    % Decrement the document counter
                    this.deccrementWorkspaceDocCount(workspace);
                end
            end
        end
    end

    methods(Access='public')
        % Constructor
        function this = MLManager(IgnoreUpdates)
            if nargin<1
                IgnoreUpdates = false;
            end
            if ~isempty(IgnoreUpdates)
                this.IgnoreUpdates = IgnoreUpdates;
            end

            % Workspaces Property
            this.Workspaces = containers.Map;
            this.WorkspaceCounts = containers.Map;

            % RegisteredWorkspaces Property
            this.RegisteredWorkspaces = containers.Map;
        end

        function index = documentIndex(this, name, workspace)
            if nargin < 3 || isempty(workspace)
                workspace = 'debug';
            end
            index = [];

            for i=1:length(this.Documents)
                doc = this.Documents(i);

                if strcmp(doc.Name, name) && ...
                        isequal(doc.Workspace, workspace)
                    index = i;
                    return;
                end
            end
        end

        function indices = documentRegexMatches(this, matchStr, workspace)
            if nargin < 3 || isempty(workspace)
                workspace = 'debug';
            end
            indices = [];

            for i=1:length(this.Documents)
                doc = this.Documents(i);

                if ~isempty(regexp(doc.Name, matchStr, "match")) && ...
                        isequal(doc.Workspace, workspace)
                    indices(end+1) = i;
                end
            end
        end

        % Delete
        function delete(this)
            try
                if ~isempty(this.Documents) && any(isvalid(this.Documents))
                    for i=length(this.Documents):-1:1
                        if isvalid(this.Documents(i))
                            delete(this.Documents(i));
                        end
                    end

    				% delete the workspace since all the documents have been
                    % deleted
                    this.cleanupAllWorkspaces;

                    if ~isempty(this.findprop('Workspace')) && ~isempty(this.Workspace) && ~isempty(this.findprop('WorkspaceKey')) && ~isempty(this.WorkspaceKey)
                        workspace = this.Workspace;
                        ws = this.WorkspaceKey;
                        this.cleanupWorkspace(workspace, ws);
                    end
                end
            catch
                % Typically only happens during testing
                internal.matlab.datatoolsservices.logDebug("variableeditor::MLManager", "Error during delete");
            end
        end

        % Cleans up the private workspace hash table
        function cleanupAllWorkspaces(this)
            % Delete all the current registered workspaces
             workspaceKeys = this.Workspaces.keys;
             for i=length(workspaceKeys):-1:1
                 ws = this.Workspaces(workspaceKeys{i});
                 if ~ischar(ws) || internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(workspaceKeys{i})
                    this.removeWorkspace(ws);
                    % delete the workspace if it is workspace created
                    % for actions
                    %TODO: refactor this such that the action classes delete their workspaces
                    if any(~cellfun('isempty', strfind(this.ACTION_WORKSPACES, workspaceKeys{i})))
                        delete(ws);
                    end
                 end

                this.cleanupWorkspace(workspaceKeys{i}, ws);
            end
        end

        %   openvar() opens a variable in Variable Editor by calling addDocument
        %   'name'           name of the workspace variable.
        %   'ws'             workspace in which the variable is present. This
        %                    defaults to 'debug' workspace. ML workspaces can be
        %                    'base'|'caller'|'debug' or a custom workspace obj. 
        %   'data'           workspace variable passed in as data, if this is passed
        %                    in, we will not evaluate to populate the data
        %   'UserContext'    Optional Context in which the variable is to be opened. For e.g 'MOTW' | 'liveeditor'
        %   'DisplayFormat'  Optional DisplayFormat when provided, the
        %                    numeric data in the variable will be displayed with this
        %                    number display format.
        function varDocument = openvar(this, name, ws, data, openvarArgs)
            arguments
                this
                name
                ws = 'debug'
                data = []
                openvarArgs.UserContext char = ''
                openvarArgs.DisplayFormat char = ''
            end

            % Get the mapped workspace
            workspace = this.getWorkspace(ws);

            if (this.isVariableOpen(name, ws))
                 % Document already exists for this variable/workspace
                 % combination
                varDocument = this.updateFocusedDocument(name, ws);
                return;
            end
            % NullValueObject - signals that we have to ask MATLAB for the
            % data
            try
                if (isempty(data) || isa(data,'internal.matlab.variableeditor.NullValueObject'))
                    try
                        data = evalin(workspace, name);
                    catch
                        data = internal.matlab.variableeditor.NullValueObject(name);
                    end
                end
            catch e % Handle to deleted objects might error, they will go through unsupported view.
            end
            varClass = class(data);
            varSize = internal.matlab.datatoolsservices.FormatDataUtils.getVariableSize(data);
            
            if ~isa(data, 'internal.matlab.variableeditor.VariableEditorMixin')
                veVar = this.getVariableAdapter(name, workspace, varClass, varSize, data, openvarArgs.UserContext);
            else
                veVar = data;
            end
            varDocument = this.addDocument(veVar, openvarArgs.UserContext, openvarArgs.DisplayFormat);
        end

        % Updates the document corresponding to the name as
        % focusedDocument
        function varDocument = updateFocusedDocument(this, name, ws)
            % Get the mapped workspace
            workspace = this.getWorkspace(ws);
            docIndex = this.documentIndex(name, workspace);
            try
                varDocument = this.Documents(docIndex);
                % Give this document focus
                this.FocusedDocument = varDocument;
            catch
                varDocument = [];
                this.FocusedDocument = varDocument;
            end
        end

        % closevar
        function closevar(this, name, ws)
            if nargin < 3 || isempty(ws)
                ws = 'debug';
            end

            % Get the mapped workspace
            workspace = this.getWorkspace(ws);
            ws = this.getWorkspaceKey(workspace);

            % Check to make sure document exists
            if isempty(documentIndex(this, name, workspace))
                return;
            end

            this.removeDocument(name, workspace);

            % Fire event when document is closed
            eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
            eventdata.Name = name;
            eventdata.Workspace = workspace;
            eventdata.Document = [];
            try
                this.notify('DocumentClosed',eventdata);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remoteManager::error", e.message);
            end
        end

        % Closes all documents that are open in the manager across all
        % workspaces
        function closeAllVariables(this)
            for i=length(this.Documents):-1:1
                if isvalid(this.Documents(i))
                    this.closevar(this.Documents(i).Name, this.Documents(i).Workspace);
                end
            end

            this.Documents = [];
            this.Workspaces = containers.Map;
            this.WorkspaceCounts = containers.Map;
        end

        % Returns a boolean to indicate if the given variable name is already
        % open in the given workspace or not.
        function isVarOpen = isVariableOpen(this, name, ws)
            if nargin < 3 || isempty(ws)
                ws = 'debug';
            end

            % Performance optimization
            if this.IgnoreUpdates
                isVarOpen = false;
                return;
            end

            workspace = this.getWorkspace(ws);
            docIndex = this.documentIndex(name, workspace);

            isVarOpen = ~isempty(docIndex) && ~this.IgnoreUpdates && ...
                    isvalid(this.Documents(docIndex)) && ...
                    isequal(this.Documents(docIndex).DataModel.Workspace, workspace);
        end

        function varDataName = getVariableAdapterClassType(this, varClass, varSize, data)
            % Get the adapter class name
            adapterClassName = this.getAdapterClassNameForData(varClass, varSize, data);
            varDataName = this.getVariableAdapterClassTypeHelper(varClass, adapterClassName);
        end

        % Derive from the static class getAdapterClassName
        function classname = getAdapterClassNameForData(this, varClass, varSize, data, userContext)
            arguments
                this
                varClass
                varSize
                data
                userContext char = ''
            end
            classname = this.getAdapterClassNameHelper(varClass, varSize, data, userContext);
        end

        % getVariableAdapter - Returns the adapter class to use for the
        % specified data
        function varAdapter = getVariableAdapter(this, name, ws, ...
                varClass, varSize, data, userContext)
            arguments
                this
                name
                ws
                varClass
                varSize
                data
                userContext char = ''
            end
            % Determine the Variable Adapter class for the given variable
            if isempty(ws)
                ws = 'debug';
            end

            % Get the mapped workspace
            workspace = this.getWorkspace(ws);

            % Get the adapter class name
            classname = this.getAdapterClassNameForData(varClass, ...
                varSize, data, userContext);
            
            % Convert the class name to a constructor function, and call
            % it with the appropriate arguments
            constructor = str2func(classname);
            varAdapter = constructor(name, workspace, data);
        end

        
        % getWorkspaceKey
        % This will return a key generated for the workspace object.  If
        % the workspace object is already a string (i.e. caller or base)
        % then that key will be returned.
        function key = getWorkspaceKey(this, workspace)
            key = '';

            if ischar(workspace)
                key = workspace;
            else
                keys = this.Workspaces.keys;
                for i=1:length(keys)
                    if (this.Workspaces(keys{i}) == workspace)
                        key = keys{i};
                        return;
                    end
                end
            end
        end

        % registerWorkspace
        % Register a workspace with a particular key
        function registerWorkspace(this, workspace, wsKey)
            this.Workspaces(wsKey) = workspace;
            this.RegisteredWorkspaces(wsKey) = workspace;
        end

        % deregisterWorkspace
        % Deregisters a workspace
        function deregisterWorkspace(this, wsKey)
            % Remove it from the registry
            if ~isempty(this.RegisteredWorkspaces) && this.RegisteredWorkspaces.isKey(wsKey)
                this.RegisteredWorkspaces.remove(wsKey);
            end

            % Attempt to remove the workspace if there are not open
            % documents, otherwise once all documents are closed it will
            % automatically be removed since it will no longer be in the
            % registry
            if ~isempty(this.Workspaces) && this.Workspaces.isKey(wsKey)
                workspace = this.getWorkspace(wsKey);
                this.removeWorkspace(workspace);
            end
        end
    end

    methods(Static)
         % getVariableAdapterClassType - Returns the class type being
        % handled by the adapter for the given variable.  This is necessary
        % because a given class type (like struct) can be handled by
        % different adapters, depending on the size.
        function varDataName = getVariableAdapterClassTypeHelper(varClass, adapterClassName)
            % If the adapter class implements a getClassType method, call
            % it.  Otherwise, just use the variable class (varClass)
            if ismethod(adapterClassName, 'getClassType')
                fnc = str2func([adapterClassName '.getClassType']);
                varDataName = fnc();
            else
                varDataName = varClass;
            end
        end

         % Returns the Adapter class name to use for the given data.
        % varClass: the classname of the data
        % varSize: the size of the data
        % data: the actual data which is opened in the variable editor
        function classname = getAdapterClassNameHelper(varClass, varSize, data, userContext)
            arguments
                varClass
                varSize
                data
                userContext char = ''
            end
            classname = '';
            varDims = length(varSize);

            switch (varClass)
                case internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes
                    if ~issparse(data)
                        classname = 'internal.matlab.variableeditor.MLNumericArrayAdapter';
                    end

                case 'struct'
                    if varDims==2
                        if varSize(1) == 0 || varSize(2) == 0
                            % Show 0-length structs in disp-view
                            classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';
                        elseif varSize(1) == 1 && varSize(2) == 1
                            classname = 'internal.matlab.variableeditor.MLStructureTreeAdapter';
                        elseif varSize(1) == 1 || varSize(2) == 1
                            % Show struct row or column vectors in array view
                            classname = 'internal.matlab.variableeditor.MLStructureArrayAdapter';
                        elseif varSize(1) ~= 0 || varSize(2) ~= 0
                            % Show MxN arrays in the object array view
                            classname = 'internal.matlab.variableeditor.MLMxNArrayAdapter';
                        end
                    end

                case 'table'
                    if internal.matlab.variableeditor.MLManager.isValidTableForDisplay(data, varDims)
                        if strcmp(userContext, 'liveeditor') || strcmp(userContext, 'VariableEditorContainerView')
                            classname = 'internal.matlab.variableeditor.MLSpannedTableAdapter';
                        else
                            classname = 'internal.matlab.variableeditor.MLTableAdapter';
                        end
                    end                   

                case 'dataset'
                    classname = 'internal.matlab.variableeditor.MLDatasetAdapter';
                    
                case {'categorical' 'nominal' 'ordinal'}
                    % Treat categorical, nominal and ordinal all the same
                    if varDims==2
                        classname = 'internal.matlab.variableeditor.MLCategoricalAdapter';
                    end

                case 'timetable'
                    if internal.matlab.variableeditor.MLManager.isValidTableForDisplay(data, varDims)
                        if strcmp(userContext, 'liveeditor') || strcmp(userContext, 'VariableEditorContainerView')
                            classname = 'internal.matlab.variableeditor.MLSpannedTimeTableAdapter';
                        else
                            classname = 'internal.matlab.variableeditor.MLTimeTableAdapter';
                        end
                    end
                case 'eventtable'
                    classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';

                case 'timetableCollection'
                    % Until they are fully supported, open timetableCollection in the unsupported view
                    classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';

                    % % Treat timetableCollections as object arrays
                    % if varDims == 2
                    %     classname = 'internal.matlab.variableeditor.MLMxNArrayAdapter';
                    % end

                case 'cell'
                    if varDims==2
                        classname = 'internal.matlab.variableeditor.MLCellArrayAdapter';
                    end

                case 'datetime'
                    if varDims==2
                        classname = 'internal.matlab.variableeditor.MLDatetimeArrayAdapter';
                    end

                case 'duration'
                    if varDims==2
                        classname = 'internal.matlab.variableeditor.MLDurationArrayAdapter';
                    end

                case 'calendarDuration'
                    if varDims==2
                        classname = 'internal.matlab.variableeditor.MLCalendarDurationArrayAdapter';
                    end

                case 'char'
                    if varDims == 2 && varSize(1) <= 1 && varSize(2) <= internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH
                        classname = 'internal.matlab.variableeditor.MLCharArrayAdapter';
                    end

                case 'string'
                    if varDims == 2 && ~(isequal(varSize, [1,1]) && strlength(data) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH)
                        classname = 'internal.matlab.variableeditor.MLStringArrayAdapter';
                    end

                case 'logical'
                    if varDims==2 && ~issparse(data)
                        classname = 'internal.matlab.variableeditor.MLLogicalArrayAdapter';
                    end

                case {'tall' 'timerange' 'gpuArray' 'distributed' 'codistributed' 'dlarray'}
                     classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';
                 
                case 'Simulink.SimulationData.Dataset'
                    classname = 'internal.matlab.variableeditor.MLSimulinkDatasetAdapter';
                otherwise
                    if (internal.matlab.variableeditor.MLManager.shouldUseCustomDisplay())
                        classname = 'internal.matlab.variableeditor.MLCustomDisplayAdapter';
                    elseif isa (data, 'optim.problemdef.OptimizationVariable') && varDims <= 2
                        classname = 'internal.matlab.variableeditor.MLObjectAdapter';
                    elseif isa(data, 'optim.problemdef.OptimizationConstraint') && varDims <= 2
                        if isLinear(data)
                            if isscalar(data)
                                classname = 'internal.matlab.variableeditor.MLOptimvarAdapter';
                            else
                                classname = 'internal.matlab.variableeditor.MLMxNArrayAdapter';
                            end
                        else
                            % For non-linear and quadratic constraints,
                            % display un-supported view.
                             classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';
                        end
                    elseif isa(data, 'optim.problemdef.OptimizationExpression') && varDims <= 2
                        if ~isNonlinear(data)
                            if isscalar(data)
                                classname = 'internal.matlab.variableeditor.MLOptimvarAdapter';
                            else
                                classname = 'internal.matlab.variableeditor.MLMxNArrayAdapter';
                            end
                        else
                            % For non-linear expressions alone, display un-supported view.
                             classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';
                        end                    
                    elseif isa(data, 'matlab.system.SystemImpl')
                        % MATLAB system objects should be shown in the
                        % unsupported view
                        classname = [];
                    elseif isa(data, 'InputOutputModel')
                        % Stateflow objects should be shown in scalar object view.
                        classname = 'internal.matlab.variableeditor.MLObjectAdapter';
                    elseif isobject(data) || all(all(ishandle(data)))
                        if ~issparse(data) && varDims == 2
                            try
                                if isnumeric(data)
                                    % Objects which claim to be numeric can be
                                    % displayed in the numeric array view (like
                                    % fi, gpuArray, etc...)
                                    classname = 'internal.matlab.variableeditor.MLNumericArrayAdapter';
                                elseif (isequal(varSize, [1, 1]) || numel(data) == 1) %#ok<ISCL>
                                    % For UDD object types, display in
                                    % unsupportedViewModel.  Need to use numel
                                    % instead of isscalar because some objects
                                    % report isscalar as false but numel of 1.
                                    if (isempty(meta.class.fromName(class(data))))
                                        classname = [];
                                    elseif (~isa(data, 'handle') || (~ismethod(data, 'isvalid') || isvalid(data))) ...
                                            && ~isa(data, 'internal.matlab.variableeditor.NullValueObject')
                                        % Show scalar objects that have public
                                        % properties in the object view.  Invalid
                                        % objects, and objects with no public
                                        % properties, are shown in the unsupported
                                        % view.
                                        if ~isempty(properties(data))
                                            classname = 'internal.matlab.variableeditor.MLObjectAdapter';
                                        else
                                            classname = [];
                                        end
                                    else
                                        classname = [];
                                    end
                                elseif isvector(data) && ~isempty(properties(data)) && ...
                                        ~internal.matlab.variableeditor.peer.PeerUtils.isLiveEditor(userContext) && ...
                                        (~ismethod(data, 'isvalid') || all(isvalid(data), 'all')) % g3042659
                                    classname = 'internal.matlab.variableeditor.MLObjectArrayAdapter';
                                else
                                    % MxN Object Arrays.  Object arrays of size 0x0
                                    % are shown in the unsupported view
                                    classname = 'internal.matlab.variableeditor.MLMxNArrayAdapter';
                                end
                            catch
                                % Certain objects can error on properties.
                                % Catch the errors and revert to the MLUnsupportedAdapter
                                classname = [];
                            end
                        end
                    end
            end

            if isempty(classname)
                classname = 'internal.matlab.variableeditor.MLUnsupportedAdapter';
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::MLManager::getAdapterClassNameHelper", "classname: " + string(classname));
        end
        
        function isOfType = isSupportedOptimvarType(data)
            isOfType = isa(data, 'optim.problemdef.OptimizationExpression') || isa(data, 'optim.problemdef.OptimizationConstraint');
        end

        function flag = shouldUseCustomDisplay(~)
            flag = false;
        end

        % Returns true if the table is valid for displaying in a tabular
        % display, and false otherwise.
        function v = isValidTableForDisplay(data, varDims)
            import internal.matlab.datatoolsservices.FormatDataUtils;
            v = false;

            % getActualTableSize returns the size after adding in the sub
            % columns of grouped columns to the column count
            actualTableSize = FormatDataUtils.getActualTableSize(data);
            w(1) = warning('off', "MATLAB:table:ModifiedVarnames");
            w(2) = warning('off', "MATLAB:table:ModifiedVarnamesLengthMax");
            c = onCleanup(@() warning(w));

            % Check for empty columns in a non-empty table
            % Set outputFormat to table, else this errors for empty
            % timetables. (g2044560)
            emptyColumns = (any(table2array(varfun(@isempty, data, 'OutputFormat', 'table'))) && ~isempty(data));

            % If the table has 2 dimensions, is less than the columns limit, and
            % doesn't have any empty columns, it can display in the Variable
            % Editor's tabular display
            if varDims==2 && ...
                    actualTableSize(2) < internal.matlab.variableeditor.MLManager.TABLE_COLUMNS_LIMIT && ...
                    ~emptyColumns
                v = true;
            end
        end

    end
end
