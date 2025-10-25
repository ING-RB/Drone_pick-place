classdef MLWorkspaceDataModel < internal.matlab.legacyvariableeditor.MLStructureDataModel
    %MLWorkspaceDataModel
    %   MATLAB Workspace Data Model
    
    % Copyright 2013-2021 The MathWorks, Inc.

    events
        VariablesAdded;
        VariablesRemoved;
        VariablesChanged;
    end

    methods(Access='public')
        % Constructor
        function this = MLWorkspaceDataModel(Workspace)
            this@internal.matlab.legacyvariableeditor.MLStructureDataModel(...
                'who', Workspace);
        end

        % workspace data changed event
        function workspaceUpdated(this, varNames)
            naninfBreakpoint = this.disableNanInfBreakpoint();
            c = onCleanup(@() this.reEnableNanInfBreakpoint(naninfBreakpoint));

            if nargin <= 1 || isempty(varNames) || ~(iscellstr(varNames) || isstring(varNames))
                varNames = {};
            end
            % varNames is for future use
            varNames = string(varNames); %#ok<NASGU>
            
            if ~this.IgnoreUpdates
                 % Capture all error messages and send back only one error
                 % update with all the errors
                errorMessages = {};
                ex = [];
                try
                    newData = evalin(this.Workspace,this.Name);
                    
                    % Sorting the data alphabetically (case-insensitive)
                    %TODO: Make this an optional selection
                    [~, sortId] = sort(lower(newData));
                    newData = newData(sortId);
                    
                    % Convert the array of structure variables into one
                    % structure with variable names as the fields and the
                    % variable as the value
                    data = struct();
                    for i=1:length(newData)
                        try
                            data.(newData{i}) = evalin(this.Workspace, newData{i});
                        catch ex
                            errorMessages{end+1} = ex.message; %#ok<AGROW>
                        end
                    end
                    varSize = size(data);
                    varClass = class(data);

                    origData = this.Data;
                    fieldNames = fieldnames(origData);
                    newFieldNames = fieldnames(data);
                    addedVariables = setdiff(newFieldNames, fieldNames);
                    removedVariables = setdiff(fieldNames, newFieldNames);
                    sameFields = intersect(fieldNames, newFieldNames);
                    this.variableChanged(data, varSize, varClass);

                    if ~isempty(addedVariables)
                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = addedVariables;
                        this.notify('VariablesAdded', wce);
                    end
                    
                    if ~isempty(removedVariables)
                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = removedVariables;
                        this.notify('VariablesRemoved', wce);
                    end
                    
                    if ~isempty(sameFields)
                        diffValues =  sameFields(cellfun(@(x)~strcmp(...
                            [this.getSizeString(origData.(x)) ' ' class(origData.(x))], ...
                            [this.getSizeString(data.(x)) ' ' class(data.(x))]), ...
                            sameFields));
                        if ~isempty(diffValues)
                            wce = internal.matlab.workspace.WorkspaceChangeEventData;
                            wce.Variables = diffValues;
                            this.notify('VariablesChanged', wce);
                        end
                    end
                catch ex
                    % We are probably evaluating in the wrong workspace!
                    errorMessages{end+1} = ex.message;
                end
                if ~isempty(errorMessages) && ...
                        ~internal.matlab.workspace.MLWorkspaceDataModel.isTransientErrorMessage(ex)
                    if ~ischar(this.Workspace)
                        error(message('MATLAB:workspace:ErrorUpdatingPrivateWorkspaceVariableList', strjoin(errorMessages,'\n')));
                    else
                        error(strjoin(errorMessages,'\n'));
                    end
                end
            end
        end

        % Executes a matlab command in the correct workspace when MATLAB is
        % available
        function evalStr = executeSetCommand(this, evalStr, varargin)
            if ischar(this.Workspace) && strcmpi(this.Workspace, 'caller')
                if nargin == 3 && ~isempty(varargin{1})
                    internal.matlab.datatoolsservices.executeCmdHandleError(evalStr, varargin{1}, true);
                else
                    internal.matlab.datatoolsservices.executeCmd(evalStr, true);
                end
            else
                evalin(this.Workspace, evalStr);
                try
                    this.workspaceUpdated();
                catch
                end
            end
        end
        
        % updateData
        function data = updateData(this, varargin)
            % Override the updateData function from the MLStructureDataModel to
            % provide extra behavior for objects which are being displayed in
            % the WSB.  For these, we don't want to hold onto a reference to
            % these, otherwise it can prevent the synchronous destruction of
            % these objects.  Instead, use an ObjectValueSummary object to store
            % it's information.
            
            % Note that the following code is similar to MLStructureDataModel
            % and MLArrayDataModel -- but it's all done here so as to be able to
            % modify objects.
            
            newData = varargin{1};
            origData = this.Data;
            
            % Get the classes for the current data.  Replace any
            % ObjectValueSummary classes with their original classes
            origDataCell = struct2cell(origData);
            classes = cell(size(origDataCell));
            for idx = 1:length(origDataCell)
                classes{idx} = class(origDataCell{idx});
                if strcmp(classes{idx}, 'internal.matlab.workspace.ObjectValueSummary')
                    classes{idx} = origDataCell{idx}.DisplayClass;
                end
            end
            
            % Get the classes for the new data
            newClasses = cellfun(@(a) class(a), struct2cell(newData), 'UniformOutput', false);
            
            classChange = ~isequaln(classes, newClasses);
            if classChange
                sameSize = numel(classes) == numel(newClasses);
            else
                % Check for data changes
                dataChange = ~this.equalityCheck(origData, newData);
                if dataChange
                    sameSize = isequal(this.getDataSize(origData), this.getDataSize(newData));
                end
            end
            
            % If there is any class change or data change
            if classChange || dataChange
                if ~sameSize
                    % Keep [I, J] consistent with the value returned in
                    % doCompare, when the number of fields in the struct
                    % has changed.
                    if classChange
                        [I,J] = meshgrid(1:size(newClasses,1),1:4);
                    else
                        [I,J] = meshgrid(1:max(size(origData,1),size(newData,1)),1:max(size(origData,2),size(newData,2)));
                    end
                else
                    [I] = this.doCompare(newData);
                    %Set J to the type column since we know the class has
                    %changed
                    J = ones(size(I))*2;
                end
                eventdata = internal.matlab.legacyvariableeditor.DataChangeEventData;
                I = I(:)';
                J = J(:)';
                eventdata.Range = [I;J];
                eventdata.DimensionsChanged = ~sameSize;
                
                % Quick check if there are any objects being displayed
                isObj = cellfun(@isobject, struct2cell(newData));
                
                if any(isObj)
                    f = fieldnames(newData);
                    fdu = internal.matlab.datatoolsservices.FormatDataUtils;
                    objs = find(isObj);
                    for idx = objs'
                        val = newData.(f{idx});
                        
                        % For any objects, replace the data in the newData
                        % struct with a representation of the object, instead of
                        % keeping a direct reference to it (using an
                        % ObjectValueSummary object)
                        dispVal = fdu.formatSingleDataForMixedView(val);
                        vs = internal.matlab.workspace.ObjectValueSummary;
                        vs.DisplayValue = dispVal;
                        vs.DisplayClass = class(val);
                        vs.DisplaySize = fdu.getSizeString(val);
                        newData.(f{idx}) = vs;
                    end
                end
                
                % Set the new data
                this.Data = newData;
                
                % The eventData Values property should represent the data
                % that has changed within the cached this.Data block as it
                % is rendered. Currently the cached data may be huge, so
                % for now don't attempt to represent it.
                eventdata.Values = [];
                this.notify('DataChange',eventdata);
            end
            
            data = this.Data;
        end

    end %methods
        
    methods(Access='protected')
        function lhs=getLHS(this, idx)
            % Return the left-hand side of an expression to assign a value
            % to a matlab structure field.  (The variable name will be
            % pre-pended by the caller).  Returns a string like: '.field'
            fieldNames = fieldnames(this.Data);
            numericIdx = str2num(idx); %#ok<ST2NM>
            lhs = fieldNames{numericIdx(1)};
        end
        
        function sizeStr = getSizeString(~, obj)
            % Returns a string representing the size.  For most cases, it
            % will be num2str(size(obj)), but this function also handles
            % java objects in the workspace
            try
                s = size(obj);
            catch
                s = [1,1];
            end
            if isnumeric(s)
                sizeStr = int2str(s);
            elseif usejava('jvm') && isjava(obj) && ismethod(s, 'toString')
                sizeStr = char(s.toString);
            else
                sizeStr = '';
            end
        end
    end
    
    methods(Static, Hidden)
        function b = isTransientErrorMessage(ex)
            % Some error messages may be transient, only happening temporarily
            % but will be resolved on their own.  For example, the
            % AccessingVariableOfExitingFunction error may be hit when hitting
            % an error after dbquit, after being stopped at a breakpoint.  But
            % when execution continues, the error is resolved and the WSB is
            % updated without a problem.

            b = false;
            if isa(ex, 'MException')
                b = (ex.identifier == "MATLAB:interpreter:AccessingVariableOfExitingFunction");
            end
        end
    end    
end
