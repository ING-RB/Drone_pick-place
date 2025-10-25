classdef PeerActionStateHandler < handle
    % Class to handle Sort Events in the LE

    % Copyright 2018 The MathWorks, Inc.

    properties
        CommandArray = [];
        CodeArray = [];
        CodeExecutionArray = [];
        MapExecutionCodeToCommand = [];
        OrigData;
        DataModel;
        PrevDataModel;
        ViewModel;
        Index;
        Direction;
        isUndoRedoAction = false;
        UndoCommandArray = [];
        Name;
        CodePublishChannel;
        BoundaryConditions = ["ConvertTo", "Clean"];
    end

    methods
        function this = PeerActionStateHandler(parentNode, variable)
            this.DataModel = variable.DataModel;
            this.OrigData = this.DataModel.Data;
            this.ViewModel = parentNode;
            this.Name = variable.Name;
            this.CodePublishChannel = '/DataToolsCodePubChannel'+"/"+ this.ViewModel.PeerNode.Id;
        end

        function executeCode(this)
            % Using a Temporary Data Model which will be updated with all
            % the user actions and then swapped out with the current Data
            % Model
            tempDM = this.OrigData;
            for i = 1:length(this.CodeExecutionArray)
                eval(this.CodeExecutionArray{i});
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
                    
                    dataIndex = executionCommand.Index;
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
                    this.ViewModel.setColumnModelProperty(dataIndex, 'IsFiltered', filtFlag);
                end
            end
            this.DataModel.Data = tempDM;
        end
        
        function executeSortCommands(this)
            tempDM = this.DataModel.Data;
            for i = 1:length(this.CodeExecutionArray)
                if contains(this.CodeExecutionArray{i}, 'sort')
                    eval(this.CodeExecutionArray{i});
                end
            end
            this.DataModel.Data = tempDM;
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

            codeGenArray = [codeGenArray, this.CommandArray(end).generatedCode];
            codeExecutionArray = [codeExecutionArray, this.CommandArray(end).executionCode];
            mapExecutionCodeToCommand = [mapExecutionCodeToCommand, length(this.CommandArray)];
            
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
                indexMatch = arrayfun(@(x)(currentCommand.Index == x), indexList);
                commandMatch = arrayfun(@(x)(strcmp(currentCommand.Command, x)), commandList);
                genFlag = any(indexMatch(indexMatch == commandMatch) ~= 0);
            end
        end
        
        function updateClientView(this, range)
            % Updates the view on the client side after data is sorted on the server
            columns = range.get('columns');
            rows = range.get('rows');
            startColumn = columns.get('start');
            endColumn = columns.get('end');
            startRow = rows.get('start');
            endRow = rows.get('end');
            if (endRow < startRow)
                endRow = startRow;
            elseif (endColumn < startColumn)
                endColumn = startColumn;
            end
            this.ViewModel.updateRowModelInformation(startRow + 1, endRow + 1);
            eventdata = internal.matlab.legacyvariableeditor.DataChangeEventData;
            eventdata.Values = [];
            eventdata.Range = [startRow:endRow, startColumn:endColumn];
            eventdata.DimensionsChanged = true;
            this.DataModel.notify('DataChange', eventdata);
            
            this.ViewModel.refreshRenderedData(struct('startRow', startRow ,'endRow', endRow, 'startColumn', startColumn, 'endColumn', endColumn));
        end

        function publishCode(this)
            % Publish the generated code to the client
            % Append isUndoRedoAction to message so server knows whether it is
            % a new sort action or an undo action
            this.CodeArray = [this.CodeArray, this.isUndoRedoAction];
            codeArrayJSON = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON('codeArray', this.CodeArray);
            % Subscriber is the LiveEditorCodePublishService
            message.publish(this.CodePublishChannel, codeArrayJSON);
            this.isUndoRedoAction = false;
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
