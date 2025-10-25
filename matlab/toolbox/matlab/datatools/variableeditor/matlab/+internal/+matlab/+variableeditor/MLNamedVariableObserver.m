classdef MLNamedVariableObserver < ...
        internal.matlab.variableeditor.VariableObserver & ...
        internal.matlab.variableeditor.NamedVariable & ...
        internal.matlab.datatoolsservices.WorkspaceListener
    %MLNAMEDVARIABLEOBSERVER Summary of this class goes here
    %  Listens for workspace changes and variable changes

    % Copyright 2013-2025 The MathWorks, Inc.

    % Workspace Listeners
    properties (SetObservable = true, Access = protected, Transient)
        WorkspaceVariablesAddedListener;
        WorkspaceVariablesRemovedListener;
        WorkspaceVariablesChangedListener;
    end

    % IgnoreUpdates
    properties (SetObservable = true)
        % IgnoreUpdates Property
        IgnoreUpdates = false;
    end

    methods
        function storedValue = get.IgnoreUpdates(this)
            storedValue = this.IgnoreUpdates;
        end

        function set.IgnoreUpdates(this, newValue)
            reallyDoCopy = ~isequal(this.IgnoreUpdates, newValue);
            if reallyDoCopy
                this.IgnoreUpdates = newValue;
            end
        end
    end

    methods(Access = public)
        % Constructor
        function this = MLNamedVariableObserver(name, workspace)
            this@internal.matlab.datatoolsservices.WorkspaceListener(isstring(workspace) || ischar(workspace) || iscellstr(workspace));
            this.Name = name;
            this.Workspace = workspace;

            if isobject(workspace)
                if ismember('VariablesAdded', events(workspace))
                    this.WorkspaceVariablesAddedListener = event.listener(workspace, 'VariablesAdded', @(es,ed)this.workspaceUpdated());
                end
                if ismember('VariablesRemoved', events(workspace))
                    this.WorkspaceVariablesRemovedListener = event.listener(workspace, 'VariablesRemoved', @(es,ed)this.workspaceUpdated());
                end
                if  ismember('VariablesChanged', events(workspace))
                    this.WorkspaceVariablesChangedListener = event.listener(workspace, 'VariablesChanged', @(es,ed)this.workspaceUpdated());
                end
            end
        end

        function workspaceUpdated(this, varNames, eventType)
            if ~isvalid(this) || this.IgnoreUpdates
                return;
            end

            if nargin <= 1 || isempty(varNames) || isobject(varNames)
                varNames = {};
            end
            if nargin <= 2
                eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
            end
            internal.matlab.datatoolsservices.logDebug("variableeditor::MLNamedVariableObserver", "workspaceUpdated:" + eventType);

            % Try to fetch new data from workspace
            try
                isEmpty = isempty(varNames);
                if ~isEmpty && isscalar(varNames)
                    varNames = strsplit(string(varNames), ',');
                end

                % g3461566: Tree structs use custom delimiters; we must convert them to periods before continuing.
                % The hope is that we eventually move on from using custom delimiters for tree structs names.
                name = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(this.Name);

                baseVarName = matlab.internal.datatoolsservices.getBaseVariableName(name);
                if isEmpty || all(strlength(varNames) == 0) ...
                        || any(strcmp(varNames, name)) ...
                        || any(strcmp(varNames, baseVarName)) ...
                        || strcmp(name, 'who') % who is special cased for filtered workspaces, TODO: refactor for better solution
                    newData = evalin(this.Workspace,name);
                    varSize = size(newData);
                    varClass = class(newData);
                    this.variableChanged(newData = newData, ...
                        newSize = varSize, ...
                        newClass = varClass, ...
                        eventType = eventType);
                end
            catch ex
                % We are probably evaluating in the wrong workspace!
                % If the variable is out of scope, provide a
                % message indicating that the variable does not
                % exist that will be displayed in the Unsupported
                % View. (g1217380)
                if isvalid(this)
                    errorMessage = getString(message('MATLAB:codetools:variableeditor:NonExistentVariable', this.Name));
                    this.variableChanged(newData = errorMessage);
                end
            end
        end

        % This method is called if an error occurred updating the whos data
        function whosError(this, exception) %#ok<INUSD>
            % Override for implementation specific handling
        end

        function delete(~)
        end
    end
end

