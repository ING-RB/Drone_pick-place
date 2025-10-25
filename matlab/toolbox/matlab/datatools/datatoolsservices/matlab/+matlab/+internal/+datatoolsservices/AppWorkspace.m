classdef AppWorkspace < handle & matlab.mixin.indexing.RedefinesDot
    %ApplicationWorkspace is an application specific workspace
    % users can assignin, evalin or call who on the workspace
    % 

    % Copyright 2020-2025 The MathWorks, Inc.

    events
        VariablesAdded;
        VariablesRemoved;
        VariablesChanged;
    end
    
    properties(Access={?matlab.internal.matlab.internal.datatoolsservices.AppWorkspace, ?matlab.unittest.TestCase})
        Workspace matlab.lang.internal.Workspace {mustBeScalarOrEmpty(Workspace)} = matlab.lang.internal.Workspace.empty
        DisableNotifications (1,1) logical = false
        PreviousVars = {}
        LastVarsChanged = string.empty; % Used to make sure we don't fire a variables changed twice
        LastVarsAdded = string.empty; % Used to make sure we don't fire a variables added twice
    end
    
    properties(Hidden, Transient, Access={?matlab.internal.datatoolsservices.AppWorkspace, ?matlab.unittest.TestCase})
        VarsChangedListener
        VarsRemovedListener
        VarsClearedListener
        Futures parallel.Future = parallel.Future.empty
    end
     
     methods
        function obj = AppWorkspace(ws, NameValueArgs)
            arguments
                ws {mustBeScalarOrEmpty(ws), mustBeA(ws, ["matlab.lang.internal.Workspace", "matlab.internal.datatoolsservices.AppWorkspace"])} = matlab.lang.internal.Workspace.empty
                NameValueArgs.CloneWorkspace (1,1) logical = true
            end

            if ~isempty(ws)
                if isa(ws, 'matlab.internal.datatoolsservices.AppWorkspace')
                    ws = ws.Workspace;
                end
                if (NameValueArgs.CloneWorkspace)
                    ws = obj.cloneLXEWorkspace(ws);
                end
            else
                ws = matlab.lang.internal.Workspace;
            end
            
            obj.Workspace = ws;
            obj.VarsChangedListener = registerVariablesChangedListener(ws, @(e)obj.fireWorkspaceChangedOrAdded(e));
            obj.VarsRemovedListener = registerVariablesDeletedListener(ws, @(e)obj.fireWorkspaceUpdatedEvent('VariablesRemoved', e));
            obj.VarsClearedListener = registerWorkspaceClearedListener(ws, @(e)obj.fireWorkspaceUpdatedEvent('VariablesRemoved', e));
        end

        function val = getValue(obj, varName)
            val = getValue(obj.Workspace, varName);
        end

        function varargout = who(obj)
            % Gets the list of variables in the workspace
            if nargout > 0
                varargout{1} = cellstr(listVariables(obj.Workspace));
            else
                evaluateIn(obj.Workspace, "who");
            end
        end
        
        function varargout = whos(obj)
            if nargout > 0
                varargout{1} = evaluateIn(obj.Workspace, "whos");
            else
                evaluateIn(obj.Workspace, "whos");
            end
        end
        
        function varargout = evalin(obj, cmd)
            % Reset the last updated variables because we don't know what
            % the evalin is doing so we can't optimize the event
            % notifications
            obj.LastVarsAdded = string.empty;
            obj.LastVarsChanged = string.empty;

            if nargout > 0
                [varargout{1:nargout}] = evaluateIn(obj.Workspace, cmd);
            else
                evaluateIn(obj.Workspace, cmd);
            end
        end
        
        function handle_errors(ws, f, errorCB)
            if ~isempty(f.Error)
                try
                    errorCB(ws, f.Error);
                catch e
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::AppWorkspace", "handle_errors error: " + e.message);
                end
            end
        end

        function varargout = evalinAysnc(obj, cmd, NVPairs)
            arguments
                obj                          (1,1) matlab.internal.datatoolsservices.AppWorkspace
                cmd                          (1,1) string
                NVPairs.CompletionCallback   function_handle = function_handle.empty
                NVPairs.NumOutputArgs        (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                NVPairs.ErrorCallback        function_handle = function_handle.empty
                NVPairs.Pool                 parallel.Pool = parallel.Pool.empty
            end

            pool = NVPairs.Pool;
            if isempty(pool)
                pool = backgroundPool();
            end
            
            future = parfeval(pool, @evalCodeInWS, 1+NVPairs.NumOutputArgs, obj, cmd, NVPairs.NumOutputArgs);
            obj.Futures(end+1) = future;
            afterEach(future, @(ws)obj.aysncFireWSEvents(ws), 0);
            if ~isempty(NVPairs.CompletionCallback)
                afterEach(future, @(ws, varargin)NVPairs.CompletionCallback(obj, varargin{:}), 0);
            end
            
            if ~isempty(NVPairs.ErrorCallback)
                afterEach(future, @(varargin)handle_errors(obj, future, NVPairs.ErrorCallback), 0);
            end
            
            afterEach(future, @(varargin)cleanupFuture(obj, future), 0);
            
            if nargout == 1
                varargout{1} = future;
            end
        end

        function cancelAllAsync(obj)
            if ~isempty(obj.Futures)
                cancel(obj.Futures);
            end
            
            obj.Futures = parallel.Future.empty;
        end

        function assignin(obj, var, value)
            isNewVar = ~obj.isvariable(var);
            assignVariable(obj.Workspace, var, value);
            obj.PreviousVars = cellstr(listVariables(obj.Workspace));
            if isNewVar
                obj.LastVarsAdded = string(var);
                obj.fireWorkspaceUpdatedEvent('VariablesAdded', {var});
            else
                obj.LastVarsChanged = string(var);
                obj.fireWorkspaceUpdatedEvent('VariablesChanged', {var});
            end
        end

        function vars = getVariables(obj)
            % Returns all variables in the workspace as a struct

            vars = struct();
            props = obj.who;
            for i=1:length(props)
                vars.(props{i}) = getValue(obj.Workspace, props{i});
            end
        end
        
        function cloneWS = clone(obj, cloneWS, nvpairs)
            % Clones the variables in workspace to the passed in workspace
            % If no workspace is passed in, it will create a new
            % matlab.internal.datatoolsservices.AppWorkspace and clone the variables to that.
            arguments
                obj                   (1,1) matlab.internal.datatoolsservices.AppWorkspace
                cloneWS               (1,1) = matlab.internal.datatoolsservices.AppWorkspace()
                nvpairs.SubsetStart   (1,1) double {mustBePositive, mustBeInteger} = 1
                nvpairs.SubsetEnd     (1,1) double {mustBeNonnegative, mustBeInteger}= 0
                nvpairs.SubsetStep    (1,1) double {mustBePositive, mustBeInteger} = 1
            end

            props = obj.who;

            for i=1:length(props)
                value = getValue(obj.Workspace, props{i});
                h = size(value,1);
                subsetStart = min(h, nvpairs.SubsetStart);
                subsetEnd = min(h, nvpairs.SubsetEnd);
                subsetStep = nvpairs.SubsetStep;
                if nvpairs.SubsetEnd == 0
                    subsetEnd = h;
                end
                
                if ~isempty(value)
                    value = value(subsetStart:subsetStep:subsetEnd,:);
                end
                assignin(cloneWS, props{i}, value);
            end
        end
        
        function delete(obj)
            delete(obj.Workspace);

            if ~isempty(obj.VarsChangedListener)
                delete(obj.VarsChangedListener);
            end

            if ~isempty(obj.VarsRemovedListener)
                delete(obj.VarsRemovedListener);
            end

            if ~isempty(obj.VarsClearedListener)
                delete(obj.VarsClearedListener);
            end
        end

        function isVar = isvariable(obj, varName)
            isVar = ismember(varName, obj.who);
        end

        %% Variable Convenience Methods (g3011409)
        function clear(obj, varName)
            % Clears variables from the workspace
            arguments
                obj                          (1,1) matlab.internal.datatoolsservices.AppWorkspace
            end
            arguments(Repeating)
                varName                      (1,1) string
            end

            clearVariables(obj.Workspace, varName{:});
        end

        function duplicate(obj, varName)
            % Duplicates variables in the workspace
            arguments
                obj                          (1,1) matlab.internal.datatoolsservices.AppWorkspace
            end
            arguments(Repeating)
                varName                      (1,1) string
            end

            for i=1:length(varName)
                newVarName = internal.matlab.datatoolsservices.VariableUtils.getVarNameForCopy(varName{i}, obj.who);
                assignin(obj, newVarName, getValue(obj, varName{i}));
            end
        end

        function rename(obj, existingVarName, newVarName)
            arguments
                obj                          (1,1) matlab.internal.datatoolsservices.AppWorkspace
                existingVarName              (1,1) string
                newVarName                   (1,1) string
            end
            % Renames a variable from existingVarName to newVarName
            % If newVarName exists it will be overridden with
            % existingVarName value
            assignin(obj, newVarName, getValue(obj, existingVarName));
            clear(obj, existingVarName);
        end

        function s = getValuesStruct(obj, vars)
            arguments
                obj 
                vars = obj.who;
            end
            s = struct;
            for i=1:length(vars)
                varName = vars{i};
                s.(varName) = obj.getValue(varName);
            end
        end
     end

    %% Methods for RedefinesDot
    methods (Access=protected)
        function varargout = dotReference(obj, indexOp)
            val = obj.getValue(indexOp(1).Name);
            if length(indexOp) > 1
                val = val.(indexOp(2:end));
            end
            [varargout{1:nargout}] = val;
        end

        function obj = dotAssign(obj, indexOp, varargin)
            varName = indexOp(1).Name;
            newValue = varargin{1};
            if obj.isvariable(varName)
                currentValue = obj.getValue(varName);
                if length(indexOp) > 1
                    % Do subsassign
                    currentValue.(indexOp(2:end)) = newValue;
                    % Set value for full copy back
                    newValue = currentValue;
                end
            end
            obj.assignin(varName, newValue);
        end
        
        function n = dotListLength(obj, indexOp, indexContext)
            s = obj.getValuesStruct;
            n = listLength(s, indexOp, indexContext);
        end
    end

    %% Private Methods
    methods(Access=private)
        function fireWorkspaceUpdatedEvent(obj, eventType, vars)
            arguments
                obj
                eventType
                vars       = string(obj.who)
            end

            if isa(vars, 'matlab.internal.mvm.eventmgr.MVMEvent') &&...
                    isstruct(vars.Details) && isfield(vars.Details, "varnames")
                vars = cellstr(vars.Details.varnames.item);
            end

            wce = matlab.internal.datatoolsservices.AppWorkspaceChangeEvent;
            wce.Type = eventType;
            wce.Workspace = obj;
            wce.Variables = vars;
            notify(obj, eventType, wce);
        end

        function fireWorkspaceChangedOrAdded(obj, ed)
            newVars = obj.who;
            diffVars = newVars(~ismember(newVars, obj.PreviousVars));
            obj.PreviousVars = newVars;
            if ~isempty(diffVars)
                fireUpdate = true;
                if ~isempty(obj.LastVarsAdded)
                    vars = string(cellstr(ed.Details.varnames.item));
                    if all(ismember(vars, obj.LastVarsAdded))
                        fireUpdate = false;
                    end
                end
                if fireUpdate
                    obj.fireWorkspaceUpdatedEvent('VariablesAdded', diffVars)
                end
            else
                fireUpdate = true;
                if ~isempty(obj.LastVarsChanged)
                    vars = string(cellstr(ed.Details.varnames.item));
                    if all(ismember(vars, obj.LastVarsChanged))
                        fireUpdate = false;
                    end
                end
                if fireUpdate
                    obj.fireWorkspaceUpdatedEvent('VariablesChanged', ed)
                end
            end
            obj.LastVarsAdded = string.empty;
            obj.LastVarsChanged = string.empty;
        end
    
        function cloneWS = cloneLXEWorkspace(obj, ws)
            arguments
                obj (1,1) matlab.internal.datatoolsservices.AppWorkspace
                ws  (1,1) matlab.lang.internal.Workspace = obj.Workspace
            end

            % Clone the workspace
            cloneWS = matlab.lang.internal.Workspace;
            arrayfun(@(var)assignVariable(cloneWS, var, getValue(ws, var)), listVariables(ws));
        end
        
        function aysncFireWSEvents(obj, ws, varargin)
            currentVars = obj.who;
            newVars = ws.who;

            % Clone currentWS
            cloneWS = obj.clone;

            % Copy values over
            obj.Workspace = obj.cloneLXEWorkspace(ws.Workspace);

            % Fire WS Events
            obj.fireIfVariablesAdded(currentVars, newVars);
            obj.fireIfVariablesChanged(cloneWS, ws);
            obj.fireIfVariablesRemoved(currentVars, newVars);
        end
        
        function fireIfVariablesAdded(obj, oldVars, newVars)
            % Fires VariablesAdded event in variables have been added to
            % the new workspace that didn't exist in the old workspace
            addedVars = newVars(~ismember(newVars, oldVars));
            if ~isempty(addedVars)
                % Variable Added event
                obj.fireWorkspaceUpdatedEvent('VariablesAdded', addedVars);
            end
        end
        
        function fireIfVariablesRemoved(obj, oldVars, newVars)
            % Fires VariablesRemoved event if variables have been removed
            % from the new workspace that existed in the old workspace
            removedVars = oldVars(~ismember(oldVars, newVars));
            if ~isempty(removedVars)
                % Variable Removed event
                obj.fireWorkspaceUpdatedEvent('VariablesRemoved', removedVars);
            end
        end
        
        function fireIfVariablesChanged(obj, oldWS, newWS)
            % Fires VariablesChanged event if there are differences between
            % variables in the workspaces
            commonVars = intersect(oldWS.who, newWS.who);
            changedVars = {};
            for i=1:length(commonVars)
                if ~isequal(getValue(oldWS.Workspace, commonVars{i}), getValue(newWS.Workspace, commonVars{i}))
                    % Simple equality check, this will capture the majority
                    % of use cases, but things like metadata will be missed
                    % (i.e. datetime Formats, table meta data)
                    changedVars{end+1} = commonVars{i}; %#ok<AGROW>
                end
            end
            
            if ~isempty(changedVars)
                % Variable Changed event
                obj.fireWorkspaceUpdatedEvent('VariablesChanged', changedVars);
            end
        end
    
        function cleanupFuture(obj, future)
            for i=1:length(obj.Futures)
                if isequal(obj.Futures(i), future)
                    obj.Futures(i) = [];
                end
            end
        end
    end

    methods(Hidden, Static)
        function expectVarName = isWSBEvalStack(stack)
            % Returns true if this eval is coming from the MLWorkspaceDataModel,
            % in which case the eval text is a variable name.
            expectVarName = false;
            try
                tb = struct2table(stack);
                if contains(tb.name(2), "MLWorkspaceDataModel")
                    expectVarName = true;
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::AppWorkspace", "isWSBEvalStack error: " + e.message);
            end
        end
    end
end

function [ws, varargout] = evalCodeInWS(ws, code, numOutputArgs)
    if numOutputArgs > 0
        [varargout{1:numOutputArgs}] = evalin(ws, code);
    else
        evalin(ws, code);
    end
 end

