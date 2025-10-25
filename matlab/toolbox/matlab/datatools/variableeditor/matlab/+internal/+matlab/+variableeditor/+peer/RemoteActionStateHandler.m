classdef RemoteActionStateHandler < handle
    % Class to handle Sort Events in the LE

    % Copyright 2018-2025 The MathWorks, Inc.

    properties
        CommandArray = [];
        CodeArray = [];
        CodeExecutionArray = [];
        MapExecutionCodeToCommand = [];
        OrigData;
        DataModel;
        PrevDataModel;
        Index;
        Direction;
        isUndoRedoAction = false;
        UndoCommandArray = [];
        Name;
        CodePublishChannel;
        BoundaryConditions = ["ConvertTo", "Clean", "SingleCellEdit", "ToolstripAction"];
        IsUserInteraction = false;
    end

    properties(WeakHandle)
        ViewModel internal.matlab.variableeditor.peer.RemoteArrayViewModel;
    end

    methods
        function this = RemoteActionStateHandler(viewModel, variable)
            this.DataModel = variable.DataModel;
            this.OrigData = this.DataModel.Data;
            if isprop(this.DataModel, 'DataI')
                this.OrigData = this.DataModel.DataI;
            end
            this.ViewModel = viewModel;
            this.Name = variable.Name;
            channel = this.ViewModel.getUID();
            this.CodePublishChannel = '/DataToolsCodePubChannel'+"/"+channel;
            this.ViewModel.setProperty('ASH_Channel', this.CodePublishChannel);
            this.IsUserInteraction = false;
        end

        function executeCode(this)
            % Using a backup variable which will be updated with all
            % the user actions and then swapped out with the current Data
            % Model
            tempDM = this.OrigData;

            % Assign the backup variable to a private workspace so it may
            % be independently mutated
            workspace = matlab.internal.datatoolsservices.AppWorkspace;
            assignin(workspace, this.Name, tempDM);
            % TODO: Current LE Actions generate execution code for a
            % "tempDM" variable, hence we need to do a second assignin.
            % Remove this once the actions are updated to always use the
            % published code instead.
            assignin(workspace, 'tempDM', tempDM);

            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteActionStateHandler", "internal executeCodenum commands: " + length(this.CodeExecutionArray));

            for i = 1:length(this.CodeExecutionArray)
                evalin(workspace, this.CodeExecutionArray{i});
                internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteActionStateHandler", "internal executeCode: " + this.CodeExecutionArray{i});

                % We need to go from the Execution code to the associated
                % Command so that we can update the icons using the
                % commandInfo
                executionCommandIndex = this.MapExecutionCodeToCommand(i);
                executionCommand = this.CommandArray(executionCommandIndex);
                if strcmp(executionCommand.Command, 'Sort')
                    if strcmpi(executionCommand.commandInfo, 'ascend')
                        direction = 'ASC';
                    else
                        direction = 'DESC';
                    end
                    this.ViewModel.setTableModelProperty('LastSorted', struct('index', executionCommand.Index-1, 'order', direction), true);
                elseif strcmp(executionCommand.Command, 'Filter')
                    % Check the CommandInfo to determing whether the column
                    % has been filtered

                    columnIndex = executionCommand.Index;
                    % We eventually want to maintain columnIndex and viewIndex separately in the executionCommand. 
                    % For now, use the view to get this mapping
                    [~, dataIndex] = this.ViewModel.getHeaderInfoFromIndex(columnIndex);

                    dataVar = this.DataModel.Data{:,dataIndex};
                    if isnumeric(dataVar) || isdatetime(dataVar)
                        if (executionCommand.commandInfo.minVal ~= min(this.OrigData{:,dataIndex}) || ...
                            executionCommand.commandInfo.maxVal ~= max(this.OrigData{:,dataIndex}) || ...
                            ~executionCommand.commandInfo.missingFlag)
                            filtFlag = true;
                        else
                            filtFlag = false;
                        end
                    else
                        if all(executionCommand.commandInfo)
                            filtFlag = false;
                        else
                            filtFlag = true;
                        end
                    end
                    % IsFilered metadata must be set on the view column index (flatted index) (E.g grouped columns/nested tables usecase)
                    this.ViewModel.setColumnModelProperty(columnIndex, 'IsFiltered', filtFlag);
                end
            end
            % Get the mutated data form the private workspace
            mutatedData = evalin(workspace, this.Name);
            % Tech Debt. Remove after refactoring LE actions
            if isequal(mutatedData, tempDM)
                mutatedData = evalin(workspace, "tempDM");
            end
            % Update the variables data model
            if isprop(this.DataModel,  'DataI')
                this.DataModel.DataI = mutatedData;
            else
                this.DataModel.Data = mutatedData;
            end
        end

        function updateIsFilteredTableModelProperty(this)
            % parse the code gen stack. If filter code is present set the
            % TableModelProperty to true
            isFiltered = false;
            codeExecutionArray = this.CodeExecutionArray;
            mapCodeExecutionToCommand = this.MapExecutionCodeToCommand;
            commandArray = this.CommandArray;

            if ~isempty(commandArray)
                for i=1:length(codeExecutionArray)
                    executionCommandIndex = mapCodeExecutionToCommand(i);
                    executionCommand = commandArray(executionCommandIndex);
                    if strcmp(executionCommand.Command, 'Filter')
                        isFiltered = true;
                        this.ViewModel.setTableModelProperty('IsFiltered', true);
                        break;
                    end
                end
            end

            if ~isFiltered
                this.ViewModel.setTableModelProperty('IsFiltered', false);                
                internal.matlab.datatoolsservices.FormatDataUtils.getSetFilteredVariableInfo(this.DataModel.Name, [], false);
            end
        end

        function executeSortCommands(this)
            if contains(this.ViewModel.userContext, 'MOTW')
                for i = 1:length(this.CodeExecutionArray)
                    if contains(this.CodeExecutionArray{i}, 'sort')
                        evalin(this.DataModel.Workspace, this.CodeExecutionArray{i});
                    end
                end
            else
                if isprop(this.DataModel, 'DataI')
                    tempDM = this.DataModel.DataI;
                else
                    tempDM = this.DataModel.Data;
                end
                workspace = matlab.internal.datatoolsservices.AppWorkspace;
                assignin(workspace, this.Name, tempDM);
                % TODO: Current LE Actions generate execution code for a
                % "tempDM" variable, hence we need to do a second assignin.
                % Remove this once the actions are updated to always use the
                % published code instead.
    
                assignin(workspace, 'tempDM', tempDM);
    
                for i = 1:length(this.CodeExecutionArray)
                    if contains(this.CodeExecutionArray{i}, 'sort')
                        evalin(workspace, this.CodeExecutionArray{i});
                    end
                end
                % Get the mutated data form the private workspace
                mutatedData = evalin(workspace, this.Name);
                % Tech Debt. Remove after refactoring LE actions
                if isequal(mutatedData, tempDM)
                    mutatedData = evalin(workspace, "tempDM");
                end
                % Update the variables data model
                if isprop(this.DataModel, 'DataI')
                    this.DataModel.DataI = mutatedData;
                else
                    this.DataModel.Data = mutatedData;
                end
            end
        end

        function getCodegenCommands(this, index, command)
            % codeGenArray is a subset of commandArray containing the commands for which code
            % needs to be generated
            codeGenArray = [];
            codeExecutionArray = [];
            mapExecutionCodeToCommand = [];

            % Logic used to filter down list of commands to only those which should generate code
            indexList = index;
            commandList = command;
            len = length(this.CommandArray);
            % Iterating from len-1 and skipping the first command as it has
            % to always be appended to end of stack
            for i = len-1:-1:1
                % lastCommand is computed for correct commandList for boundary conditions. If a current condn
                % is boundary and is immediately preceded by a boundary condn, we still want the following logic
                lastCommand = this.CommandArray(min(i+1,len));
                if ~(this.checkGenerateCommand(this.CommandArray(i), indexList, commandList, lastCommand))
                    codeGenArray = [codeGenArray, this.CommandArray(i).generatedCode];
                    codeExecutionArray = [codeExecutionArray, this.CommandArray(i).executionCode];
                    mapExecutionCodeToCommand = [mapExecutionCodeToCommand, i];
                    % For Boundary conditions, remove indexList and commandList to prevent it from being replaced.
                    if (this.isBoundaryCondition(this.CommandArray(i)))
                        indexList = [];
                        commandList=[];
                    else
                        indexList = [indexList, this.CommandArray(i).Index];
                        commandList = [commandList, this.CommandArray(i).Command];
                    end
                end
            end
            codeGenArray = fliplr(codeGenArray);
            codeExecutionArray = fliplr(codeExecutionArray);
            mapExecutionCodeToCommand = fliplr(mapExecutionCodeToCommand);
            if ~isempty(this.CommandArray)
                codeGenArray = [codeGenArray, this.CommandArray(end).generatedCode]; 
                codeExecutionArray = [codeExecutionArray, this.CommandArray(end).executionCode];
                mapExecutionCodeToCommand = [mapExecutionCodeToCommand, length(this.CommandArray)];
            end

            idx = find(strcmp(codeGenArray, ';'));
            if (idx)
                codeGenArray(idx) = [];
                codeExecutionArray(idx) = [];
                mapExecutionCodeToCommand(idx) = [];
            end
            if isempty(codeGenArray)
                codeGenArray = {';'};
            end
            this.CodeArray = codeGenArray;
            this.CodeExecutionArray = codeExecutionArray;
            this.MapExecutionCodeToCommand = mapExecutionCodeToCommand;
        end

        % Utility method that returns true if the command is a boundary
        % condition and false if not.
        function isBoundary = isBoundaryCondition(this, command)
            commandName = command.Command;
            isBoundary = ~(isempty(find(this.BoundaryConditions==commandName,1)));
        end


        % Tells whether we consolidate any previously generated commands(commandList) for the same column(indexList)
        % If boundary conditions, then we do not replace existing commands
        % by default unless we are preceded by a boundary condition or the action is on a new column.
        function genFlag = checkGenerateCommand(this, currentCommand, indexList, commandList, lastCommand)
            if this.isBoundaryCondition(currentCommand)
                genFlag = false;
            else
                if isempty(currentCommand.Index)
                    genFlag = false;
                else
                    indexMatch = arrayfun(@(x)(currentCommand.Index == x), indexList);
                    commandMatch = arrayfun(@(x)(strcmp(currentCommand.Command, x)), commandList);
                    genFlag = any(indexMatch(indexMatch == commandMatch) ~= 0);
                end
            end
        end

        function updateClientView(this, sizeChanged)
            % Updates the view on the client side after actions are fired
            % on the server

            dataSize = this.ViewModel.getTabularDataSize();

           % MetaData update should be taken care of by individual actions,
           % as not all of them want metadata update

            % Update entire dataSize so that buffers outside the viewport
            % are cleared.
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = 1;
            eventdata.StartColumn = 1;
            eventdata.EndRow = dataSize(1);
            eventdata.EndColumn = dataSize(2);
            
            if (nargin < 2)
                sizeChanged = true;
            end
            eventdata.SizeChanged = sizeChanged;
           
            % dataChange will cause view to refresh with updated data.
            this.DataModel.notify('DataChange', eventdata);
        end

        function publishCode(this, columnIndex)
            arguments
                this
                columnIndex = []
            end
            % Publish the generated code to the client
            % Append isUndoRedoAction to message so server knows whether it is
            % a new sort action or an undo action
            this.updateCodeArrayState();
            this.updateModelProperties();
            codeToPublish = this.CodeArray;
            if (length(codeToPublish) > 1) && contains(this.ViewModel.userContext, 'MOTW')
                % Index of filtered column should also match index of command
                if ~isempty(columnIndex)
                    commandIndices = this.MapExecutionCodeToCommand();
                    if ~isempty(commandIndices)
                        lastCommandIndex = commandIndices(end);
                        executionCommand = this.CommandArray(lastCommandIndex);
                        if ~isequal(executionCommand.Index, columnIndex)
                            return;
                        end
                    end
                end
                codeToPublish = codeToPublish(end-1);
            end
            codeArrayJSON = internal.matlab.variableeditor.peer.PeerUtils.toJSON('codeArray', codeToPublish);
            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteActionStateHandler", "publishCode: " + codeToPublish);
            % Subscriber is the LiveEditorCodePublishService
            message.publish(this.CodePublishChannel, codeArrayJSON);
        end

        function updateCodeArrayState(this)
            this.CodeArray = [this.CodeArray, this.isUndoRedoAction];
        end

        function updateModelProperties(this)
            this.updateIsFilteredTableModelProperty();
        end

        function setIsUndoRedoAction(this, isEnabled)
            this.isUndoRedoAction = isEnabled;
        end

        function handleSortFilterIcon(this)
            index = this.CommandArray(end).Index;
            if strcmp(this.CommandArray(end).Command, 'Filter')
                    this.ViewModel.setColumnModelProperty(index, 'IsFiltered', false);
            elseif strcmp(this.CommandArray(end).Command, 'Sort')
                order = this.CommandArray(end).commandInfo;
                % Remove the LastSorted Flag if it is an undo action
                this.ViewModel.setTableModelProperty('LastSorted', struct('index', index, 'order', order), true);
            end
        end

    end
end
