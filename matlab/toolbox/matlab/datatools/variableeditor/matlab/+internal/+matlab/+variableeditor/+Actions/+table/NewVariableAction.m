classdef NewVariableAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles creation of a new variable as table/separate
    % workspace variable or new char/numeric/cell array.

    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'NewWorkspaceVariable'
    end  
    
    properties(Transient)
        VariableAddedListener
    end
    
    methods
        function this = NewVariableAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.table.NewVariableAction.ActionName;           
            props.Enabled = true; 
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end       
    end
    
    methods(Access='protected')
        % Generates command for generating new variables from the current
        % selection. For SeperateWorkspaceVariable, we need to loop into
        % current column selection range to generate individual column
        % variables.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            focusedView = focusedDoc.ViewModel;
            % use getSelectionIndices to fetch selection. For
            % timetables/tables, this returns offset indices
            selection = focusedView.getSelectionIndices;
            sz = focusedView.getTabularDataSize();
            [rowRange, colRange] = this.getNumericSelectionRange(selection,sz);
            preSelectionRange = internal.matlab.variableeditor.Actions.table.NewVariableAction.computePreSelectionRange(focusedView, ...
                rowRange, focusedDoc.Name, actionInfo.menuID);
            
            selectionRange = [rowRange, ',' colRange];           
            cmd = '';
            % Callback to detect variable names from correct workspace.                
            if strcmp(actionInfo.menuID, 'SeparateWorkspaceVariable')
                [cmd, executionCmd] = this.handleSeparateWorkspaceVariableCreation(focusedDoc, rowRange);
            elseif strcmp(actionInfo.menuID, 'NewVariableFromCurrentView') || strcmp(actionInfo.menuID, 'NewTableFromDataset')
                newVarPrefix = '';
                if isfield(actionInfo, 'NewVariablePrefix')
                    newVarPrefix = actionInfo.NewVariablePrefix;
                end
                variableName = [newVarPrefix focusedDoc.Name];
                fnames = evalin('debug', 'who');
                newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  fnames');
                if strcmp(actionInfo.menuID, 'NewTableFromDataset')
                    cmd = sprintf('%s = dataset2table(%s);', newVarName, focusedDoc.Name);
                else
                    cmdToPublish = sprintf('%s=%s;', newVarName, focusedDoc.Name);
                    internal.matlab.desktop.commandwindow.insertCommandIntoHistory(cmdToPublish);
                end
                executionCmd = sprintf('openvar("%s"); ', newVarName);
            else
                variableName = focusedDoc.Name;
                columnsSelected = selection{2};
                if isa(focusedView.DataModel.Data, 'dataset')
                    varNames = focusedView.DataModel.Data.Properties.VarNames;
                else
                    varNames = focusedView.DataModel.Data.Properties.VariableNames;
                end
                % For 'NewStringArray', 'NewNumericArray','NewCharacterArray', 
                % generate newvarname based on column Variable rather than table name if the
                % selection is within the same column. for E.g if t = array2table(rand(2))
                % columnsSelected = [1,2], then baseName = t1, but if
                % columnsSelected = [1,1], then baseName = 'Var1'
                if columnsSelected(1) == columnsSelected(2) && ~strcmp(actionInfo.menuID, 'NewTable') && ~strcmp(actionInfo.menuID, 'NewDataset')
                    baseName = varNames{columnsSelected(1)};
                else
                    baseName = variableName;
                end
                [cmd, executionCmd] = this.handleNewWorkspaceVariableCreation(actionInfo.menuID, baseName, variableName, selectionRange, preSelectionRange);
            end
        end

        % Handles creation of separate workspace variables. this extends
        % for every column part of the current selection. for e.g
        % t = array2table(rand(10)), rowSelection=[3,5;7,8], colSelection=[2,2;4,4]
        % codegen: Var2 = t.Var2([3:5,7:8]); Var4 = t.Var4([3:5,7:8]);

        function [cmd, openvarCmd] = handleSeparateWorkspaceVariableCreation(~, focusedDoc, rowRange)
            variableName = focusedDoc.Name;
            focusedView = focusedDoc.ViewModel;            
            selection = focusedView.getSelection;
            columnsSelected = selection{2};        
            if isa(focusedView.DataModel.Data, 'dataset')
                varNames = focusedView.DataModel.Data.Properties.VarNames;
            else
                varNames = focusedView.DataModel.Data.Properties.VariableNames;   
            end
            cSize = size(columnsSelected); 
            fnames = evalin('debug', 'who');
            openvarCmd = '';            
            cmd = '';            
            for j=1:cSize(1)
               actualStart = columnsSelected(j,1);
               actualEnd = columnsSelected(j,2);
               len = actualEnd-actualStart+1;
               dataIdx = 1;
               gcolCounts = focusedView.getGroupedColumnCounts();
               if ~isempty(gcolCounts)
                  [actualStart, actualEnd, dataIdx] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(actualStart, actualEnd, gcolCounts);
               end
               for k =  actualStart: actualEnd
                  varName = varNames{k};
                  newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(varName,  fnames');    
                  if ~isvarname(varName)
                        if isa(focusedView.DataModel.Data, 'dataset')
                            [~,~,varName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentStringDataset(varName, variableName, NaN);
                        else
                            [~,~,varName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(varName, variableName, NaN);
                        end
                        varName = ['(' char(varName) ')'];
                  end
                  if (~isempty(gcolCounts) && gcolCounts(k) > 1)
                     colRange = internal.matlab.variableeditor.TableViewModel.getColumnSubstringForGroupedCol(columnsSelected(j,1), columnsSelected(j,2),k, gcolCounts);
                     cmd = [cmd sprintf('%s = %s.%s(%s,%s); ', newVarName, variableName, varName, rowRange, colRange)];
                  else
                     cmd = [cmd sprintf('%s = %s.%s(%s); ', newVarName, variableName, varName, rowRange)];
                  end
                   openvarCmd = [openvarCmd sprintf('openvar("%s"); ', newVarName)];
                   fnames(end+1) = {char(newVarName)};
               end
            end
        end

        % Handles creation of a new table/cell/numeric/char/string type. for e.g
        % t = array2table(rand(10)), rowSelection=[3,5;7,8], colSelection=[2,2;4,4]
        % codegen for new table: t1 = t([3:5,7:8],[2,4]);;
        % codegen for new numeric array: t1 = t{[3:5,7:8],[2,4]};
        function [cmd, openvarCmd] = handleNewWorkspaceVariableCreation(~, menuID, baseName, variableName, selectionRange, preSelectionRange)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            fnames = evalin('debug', 'who');    
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(baseName,  fnames');
            variableType = evalin('debug', "class(" + variableName + ")");
            if strcmp(menuID, 'NewTable') || strcmp(menuID, 'NewTimeTable') || strcmp(menuID, 'NewDataset')              
                cmd = sprintf('%s = %s(%s);',newVarName, variableName, selectionRange);
            elseif ismember(menuID, {'NewStringArray', 'NewNumericArray', 'NewCharacterArray'})
                if variableType == "dataset"
                    cmd = sprintf('%s = dataset2table(%s); %s = %s{%s};', newVarName, variableName, newVarName, newVarName, selectionRange);
                else
                    cmd = sprintf('%s = %s{%s};', newVarName, variableName, selectionRange);
                end
            elseif strcmp(menuID, 'NewCellArray')
                % For cellArrays that incl preSelectionRange, concatenate
                % ranges along with the cell conversion code.
                if variableType == "dataset"
                    varObsNamesEmpty = evalin('debug', "isempty(" + variableName + ".Properties.ObsNames)");
                    if ~isempty(preSelectionRange)
                        if ~varObsNamesEmpty
                            cmd = sprintf('%s = [%s dataset2cell(%s(%s))]; %s = %s(2:end,2:end);', newVarName, preSelectionRange, variableName, selectionRange, newVarName, newVarName);
                        else
                            cmd = sprintf('%s = [%s dataset2cell(%s(%s))]; %s = %s(2:end,:);', newVarName, preSelectionRange, variableName, selectionRange, newVarName, newVarName);
                        end
                    else
                        if ~varObsNamesEmpty
                            cmd = sprintf('%s = dataset2cell(%s(%s)); %s = %s(2:end,2:end);',newVarName, variableName, selectionRange, newVarName, newVarName);
                        else
                            cmd = sprintf('%s = dataset2cell(%s(%s)); %s = %s(2:end,:);',newVarName, variableName, selectionRange, newVarName, newVarName);  
                        end
                    end
                else
                    if ~isempty(preSelectionRange)
                        cmd = sprintf('%s = [%s table2cell(%s(%s))];', newVarName, preSelectionRange,  variableName, selectionRange);
                    else
                       cmd = sprintf('%s = table2cell(%s(%s));',newVarName, variableName, selectionRange);  
                    end
                end
            end
            openvarCmd = sprintf('openvar(''%s'');', newVarName);
        end
    end
    
    methods(Static)
        
        % Computes preselection ranges for certain creations. For a
        % cellarray from a timetable that includes time column, we should
        % be including RowTimes in the CellArray.
        function preSelectionRange = computePreSelectionRange(focusedView, rowRange, varName, actionID)
            selection = focusedView.getSelection();
            sz = focusedView.getTabularDataSize();
            rows = selection{1};
            cols = selection{2};
            preSelectionRange = '';
             if isa(focusedView.DataModel.getCloneData, 'timetable') && ~isempty(rows) && ~isempty(cols) && strcmp(actionID, 'NewCellArray') && ~isempty(find(cols==1,1))
                 rowSubset = sprintf('(%s)', rowRange);
                 % If all rows are selected, do not index RowTimes with :, this currently errors.
                 if (height(rows)==1 && rows(2)-rows(1) + 1 == sz(1))
                    rowSubset = '';                    
                 end                 
                 preSelectionRange = sprintf('mat2cell(%s.Properties.RowTimes%s, ones(length(%s.Properties.RowTimes%s) ,1), 1)', varName, rowSubset, varName, rowSubset);
             end
        end
    end
end


