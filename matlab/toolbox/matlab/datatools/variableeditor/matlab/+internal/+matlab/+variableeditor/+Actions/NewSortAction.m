classdef NewSortAction < internal.matlab.variableeditor.VEAction 
    %NewSortAction
    %Sort Action for tables|timetables in Live Editor
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'NewSortAction'
    end
    
    methods
        function this = NewSortAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.NewSortAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.NewSort;
        end
        
        function NewSort(this, sortInfo)
            index = sortInfo.actionInfo.index + 1;
            order = sortInfo.actionInfo.order;
            if strcmpi(order, 'ASC')
                direction = 'ascend';
            else
                direction = 'descend';
            end
            
            idx = arrayfun(@(x) isequal(x.DocID, sortInfo.docID), this.veManager.Documents);
            sh = this.veManager.Documents(idx).ViewModel.ActionStateHandler;
            
            sh.ViewModel.setTableModelProperty('LastSorted', struct('index', index -1, 'order', order), true);

            % Honor MissingPlacement syntax in sortrows command
            s = settings;
            missingPlacementValue = s.matlab.desktop.variables.sorting.MissingValuePlacement.ActiveValue;

             % Performs the sort by calling the sortrows command
            view = sh.ViewModel;
            parentIndicesMetaData = view.getColumnModelProperty(index, 'ParentIndex');
            if ~isempty(parentIndicesMetaData)
                parentIndicesMetaData = parentIndicesMetaData{1};
            end
            nestedSortIdx = [];
            data = sh.DataModel.Data;
            varName = sh.Name;
            sortIndex = index;
            executionVarName = 'tempDM';
            if ~isempty(parentIndicesMetaData)
                sortIndex = view.getColumnModelProperty(index, 'ColumnIndex');
                sortIndex = str2double(sortIndex{1});
                pIndex = parentIndicesMetaData(1);
                levels = strsplit(pIndex, '__');
                % Get all levels in a numeric array
                levelIdx = str2double(strsplit(levels(end), '_'));
                levelIdx = levelIdx(~ismissing(levelIdx));

                dotSubscript = varName;
                executionDotSubscript = executionVarName;
                for i=1:length(levelIdx)
                    idx = levelIdx(i);
                    tabularDotSubscript = matlab.internal.tabular.generateDotSubscripting(data, idx, '');
                    dotSubscript = [dotSubscript tabularDotSubscript];
                    executionDotSubscript = [executionDotSubscript tabularDotSubscript];                    
                    data = data.(levelIdx(i));
                end
                varName = dotSubscript;
                executionVarName = executionDotSubscript;
                [~, nestedSortIdx, shouldGenerateMissingPlacement] = this.sortDataModel(data, sortIndex, direction, missingPlacementValue);
                sh.DataModel.Data = sh.DataModel.Data(nestedSortIdx,:);
            else
                % For tables containing grouped columns, sortIndex needs to be offset w.r.t view index. 
                % Use getHeaderNameFromIndex API to get the offset index.
                [~,sortIndex] = sh.ViewModel.getHeaderInfoFromIndex(index);
                [sortedData, ~, shouldGenerateMissingPlacement] = this.sortDataModel(data, sortIndex, direction, missingPlacementValue);
                sh.DataModel.Data = sortedData;
            end
            
            % Sort the filtering workspace if filtering feature is enabled
            
            % Size does not change when we sort, update client view
            % accordingly.
            sh.updateClientView(false);
            sh.ViewModel.updateRowMetaData();

            missingPlacementSyntax = "";
            if shouldGenerateMissingPlacement
               missingPlacementSyntax = ", ""MissingPlacement"", """ + missingPlacementValue + """";
            end
            
            codegenSyntax = this.sortCodeGen(sh, data,  varName, struct('Index', sortIndex, 'Direction', direction, 'isNestedSort', ~isempty(nestedSortIdx)), missingPlacementSyntax);
            % executionCodegenSyntax = this.sortCodeGen(sh, data,  executionVarName, struct('Index', index, 'Direction', direction, 'isNestedSort', ~isempty(nestedSortIdx)), missingPlacementSyntax);
            mCode = {codegenSyntax};
            
            if ~isempty(nestedSortIdx)
                executionCode = {sprintf('[~,idx] = sortrows(%s, %d, "%s"%s);tempDM = tempDM(idx, :); clear idx;', executionVarName, sortIndex, direction, missingPlacementSyntax)};
            else
                executionCode = {sprintf('tempDM = sortrows(tempDM, %d, "%s"%s);', sortIndex, direction, missingPlacementSyntax)};
            end
            
            % commandArray contains a list of call the interactive sort commands issued for a output
            sh.CommandArray = [sh.CommandArray, struct('Command', "Sort", 'Index', index, 'commandInfo', direction, ...
                'generatedCode', {mCode}, 'executionCode', {executionCode})];
                
            sh.getCodegenCommands(index, "Sort");
            sh.publishCode();
            
            % Publish to any MATLAB listeners on the View since this action
            % is use by both the LE and VE.
            eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
            eventdata.UserAction = '';
            eventdata.Index = index;
            eventdata.DataIndex = sortIndex;
            eventdata.Code = mCode;
            sh.ViewModel.notify('UserDataInteraction', eventdata);
        end

        % This API Does a localized sort on the DataModel's data passed in.
        % (Either top level or nested data) from the sortIndex/direction
        % and MissingPlacement value
        function [sortedData, sortIndices, shouldGenerateMissingPlacement] = sortDataModel(this, data, sortIndex, direction, missingPlacementValue)
            % If MissingPlacement is default or data is of type cell, do
            % not generate MissingPlacement syntax, sortrows will error.
            shouldGenerateMissingPlacement = ~strcmp(missingPlacementValue, "auto") && ~iscell(data.(sortIndex));
            if shouldGenerateMissingPlacement
                [sortedData, sortIndices] = sortrows(data, sortIndex, direction, "MissingPlacement", missingPlacementValue);
            else
                [sortedData, sortIndices] = sortrows(data, sortIndex, direction);
            end
        end
        
        function sortCode = sortCodeGen(~, sh, data, varName, commandInfo, missingPlacementSyntax)
            arguments
                ~
                sh
                data = sh.DataModel.Data
                varName = sh.Name
                commandInfo = struct
                missingPlacementSyntax = ""
            end
            % Function to generate code for the sort operation
            idx = commandInfo.Index;
            colName = data.Properties.VariableNames{idx};
            [~,~,colName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, varName, NaN);
            
            dir = commandInfo.Direction;
            lhs = varName;
            postRhs = "";
            fnames = evalin('debug', 'who');
            indexName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName('index',  fnames');
            if commandInfo.isNestedSort
                lhs = "[~, " + indexName + "]";
                postRhs = sprintf('%s = %s(%s, :); clear %s; %s;', sh.Name, sh.Name, indexName, indexName, sh.Name);
            end

            % Add the direction to the generated code only if descending
            if strcmp(dir, 'ascend')
                sortCode = lhs + " = sortrows(" + varName + ", " + colName + missingPlacementSyntax + ");" + postRhs;
            else
                sortCode = lhs + " = sortrows(" + varName + ", " + colName + ", """ + dir + """" + missingPlacementSyntax + ");" + postRhs;
            end
        end
        
        function  UpdateActionState(this)
            this.Enabled = true;
        end
         
    end
end

