classdef EditCheckboxAction < internal.matlab.variableeditor.VEAction
    %EditCheckboxAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'EditCheckboxAction'
    end

    methods
        function this = EditCheckboxAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.EditCheckboxAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.EditCheckbox;
        end
        
        function EditCheckbox(this, editInfo)
            idx = arrayfun(@(x) isequal(x.DocID, editInfo.docID), this.veManager.Documents);
            
            % sh = StateHandler. 
            % The stateHandler takes care of of updating the output state
            % in response to actions
            sh = this.veManager.Documents(idx).ViewModel.ActionStateHandler;
            
            channel = strcat('/VE/filter',editInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            % Refresh all filter views on the filterManager.
            internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshViews(mgr);
            colIndex = editInfo.actionInfo.index + 1;
            [colName, columnDataIndex] = sh.ViewModel.getHeaderInfoFromIndex(colIndex);
            colClass = this.getColumnClass(colIndex, columnDataIndex, sh.ViewModel);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            % tws = TabularVariableFilteringWorkspace
            tws = mgr.Workspaces('filterWorkspace');
            userAction = editInfo.actionInfo.userAction;
            if (strcmp(userAction, 'SelectAll'))
                if (all(tws.(['unsearched_' num2str(columnDataIndex)]).Selected(:) == true))
                    sh.ViewModel.setColumnModelProperty(colIndex, 'IsFiltered', false);
                    return;
                end
                tws.selectAll(colName);
            end
            
            if (strcmp(userAction, 'ClearAll'))
                if (all(tws.(['unsearched_' num2str(columnDataIndex)]).Selected(:) == false))
                    return;
                end
                tws.deselectAll(colName); 
            end
            
            unsearchedCol = tws.(['unsearched_' num2str(columnDataIndex)]);
            includeMissing = unsearchedCol.Selected(1);
            numChecked = sum(unsearchedCol.Selected == true);

            if strcmp(colClass, 'logical') || strcmp(colClass, 'char')
                unsearchedCol_clean = unsearchedCol;
                includeMissing = false;
            else
                unsearchedCol_clean = unsearchedCol(2:end, :);
            end
            
            % Use the number of checked vs unchecked rows to determine
            % whether to generate selection vs deselection code
            if (numChecked >= (height(unsearchedCol) - numChecked) && ~strcmp(colClass, 'logical'))
                [mCode, executionCode] = this.genDeselectCode(sh, colName, colClass, unsearchedCol_clean, includeMissing);
            else
                [mCode, executionCode] = this.genSelectCode(sh, colName, colClass, unsearchedCol_clean, includeMissing);
            end
            
            % Update the DataModel with the filtered table
            sh.DataModel.Data = tws.FilteredTable;
            
            % Set the isFiltered Property so the Filtering Icons appear                       
            isFiltered = true;
            if (all(unsearchedCol.Selected))
                isFiltered = false;            
            end
            sh.ViewModel.setColumnModelProperty(colIndex, 'IsFiltered', isFiltered);

            sh.IsUserInteraction = true;
            % Update the client with the filtered view 
            sh.updateClientView();
            sh.ViewModel.updateRowMetaData();
                        
            % commandArray contains a list of all the interactive sortand filter commands issued for a output
            sh.CommandArray = [sh.CommandArray, struct('Command', "Filter", 'Index', colIndex, 'commandInfo', unsearchedCol.Selected, ...
                'generatedCode', {mCode}, 'executionCode', {executionCode})];
                
            sh.getCodegenCommands(colIndex, "Filter");
            sh.IsUserInteraction = true;
            sh.publishCode(colIndex);
            
            % Update the filtering view of the embedded table
            if (strcmp(userAction, 'SelectAll') || strcmp(userAction, 'ClearAll'))
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateHeaderMenuForViewport(mgr, colName);
            end
            
            % Execute all sort commands
            sh.executeSortCommands();

            % Publish to any MATLAB listeners on the View since this action
            % is use by both the LE and VE.
            eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
            eventdata.UserAction = 'Filter';
            eventdata.Index = colIndex;
            % When tables have nested tables/grouped columns, data index is different from column Index.
            eventdata.DataIndex = columnDataIndex;
            eventdata.Code = mCode;
            sh.ViewModel.notify('UserDataInteraction', eventdata);
        end
        
        function UpdateActionState(this)
            this.Enabled = true;
        end
    end

    methods(Access=private)
        function columnClass = getColumnClass(~, columnIndex, columnDataIndex, viewModel)
            columnClass = viewModel.getColumnModelProperty(columnIndex, "class");
            % If class columnModelProperty does not exist, derive
            % columnClass from the data
            try
                if strcmp(columnClass, '')
                    data = viewModel.DataModel.Data;
                    columnClass = {class(data.(columnDataIndex))};
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::EditCheckboxAction::getColumnClass", e.message);
            end
        end
    end
    
    methods(Static)
        function [filtCode, executionCode] = genSelectCode(sh, cName, cClass, wsVar, includeMissing)
            vName = sh.Name;
            filtNames = wsVar.Values(wsVar.Selected == true);
            nFiltNames = size(filtNames,1);
            [quotes, braces_o, braces_c] = internal.matlab.variableeditor.peer.PeerUtils.getCodegenConstructsForDatatype(cClass);
            filtNames_clean = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen(filtNames, quotes, cClass);
            filtNames_clean = strjoin(filtNames_clean, {','});
            % For chars, set includeMissing to false as we do not want to filter for missing in codegen 
            isChar = strcmp(cClass, 'char');
            if isChar
                includeMissing = false;
            end
            if includeMissing
                if (nFiltNames == 0)
                    % If there are no items that have been selected (Entire list is unchecked)
                    filtCode = {[vName ' = ' vName '(ismissing(' vName '.' cName '),:);']};
                    executionCode = {sprintf('tempDM = tempDM(ismissing(tempDM.%s),:);', cName)};
                elseif (nFiltNames == 1)
                    % If only 1 item has been selected  (Only one items in list in checked)
                    if internal.matlab.variableeditor.peer.PeerUtils.isStringOrCategoricalLike(cClass)
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' filtNames_clean ' | ismissing(' vName '.' cName '),:);']};
                    else
                        filtCode = {[vName ' = ' vName '(strcmp(' vName '.' cName ',' filtNames_clean ') | ismissing(' vName '.' cName '),:);']};
                    end
                    executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s, %s) | ismissing(tempDM.%s),:);', ...
                        cName, filtNames_clean, cName)};
                else
                    % If multiple items have been selected (More than 1 item in list is checked)
                    filtCode = {[vName ' = ' vName '(ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c ') | ismissing(' vName '.' cName '),:);']};
                    executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s,%s%s%s) | ismissing(tempDM.%s),:);', ...
                        cName, braces_o, filtNames_clean, braces_c, cName)};
                end
            else
                if (nFiltNames == 0)
                    % If there are no items that have been selected (Entire list is UN-checked)
                    filtCode = {[vName '(:,:) = [];']};
                    executionCode = {sprintf('tempDM(:,:) = [];')};
                elseif (nFiltNames == 1 && (~all(wsVar.Selected == true)))
                    % If only 1 item has been selected  (Only one items in list in checked)
                    if (internal.matlab.variableeditor.peer.PeerUtils.isStringOrCategoricalLike(cClass) || strcmp(cClass, 'logical'))
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' filtNames_clean ',:);']};
                        executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                    elseif isChar 
                        % For single spaces, detect explicitly and generate
                        % isspace syntax for filtering
                        if isspace(filtNames{1})
                            filtCode = {[vName ' = ' vName '(isspace(' vName '.' cName '),:);']};   
                            executionCode = {sprintf('tempDM = tempDM(isspace(tempDM.%s),:);', cName)};
                        else
                            % For single chars, use ismember code for
                            % filtering (strcmp returns a scalar logical)
                            filtCode = {[vName ' = ' vName '(ismember(' vName '.' cName ',' filtNames_clean '),:);']};
                            executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                        end
                    else
                        filtCode = {[vName ' = ' vName '(strcmp(' vName '.' cName ',' filtNames_clean '),:);']};
                        executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                    end
                else
                    if strcmp(cClass, 'logical')
                        % g1778901: Do not generated ~isMissing code for logicals since they have no missing.
                        filtCode = {[';']};
                        executionCode = {sprintf('tempDM = this.OrigData;')};
                    elseif isChar
                        hasSpaces = cellfun(@isspace, filtNames);
                        % For combinations of spaces and char members,
                        % generate ismember | isspace code
                        if any(hasSpaces)
                            filtNamesWithoutSpace = filtNames(~hasSpaces);
                            filtNames_clean = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen(filtNamesWithoutSpace, quotes, cClass);
                            filtNames_clean = strjoin(filtNames_clean, {','});
                            filtCode = {[vName ' = ' vName '((ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c ') | isspace(' vName '.' cName ')),:);']};
                            executionCode = {sprintf('tempDM = tempDM((ismember(tempDM.%s,%s%s%s) | isspace(tempDM.%s)),:);', cName, ...
                                braces_o, filtNames_clean, braces_c, cName)};
                        else
                            filtCode = {[vName ' = ' vName '(ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c '),:);']};
                            executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s,%s%s%s),:);', ...
                                cName, braces_o, filtNames_clean, braces_c)};
                        end
                    else
                        % If multiple items have been selected (More than 1 item in list is checked)
                        filtCode = {[vName ' = ' vName '(ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c '),:);']};
                        executionCode = {sprintf('tempDM = tempDM(ismember(tempDM.%s,%s%s%s),:);', ...
                            cName, braces_o, filtNames_clean, braces_c)};
                    end
                end
            end
        end
        
        function [filtCode, executionCode] = genDeselectCode(sh, cName, cClass, wsVar, includeMissing)
            vName = sh.Name;
            filtNames = wsVar.Values(wsVar.Selected == false);
            nFiltNames = size(filtNames,1);
            [quotes, braces_o, braces_c] = internal.matlab.variableeditor.peer.PeerUtils.getCodegenConstructsForDatatype(cClass);
            filtNames_clean = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen(filtNames, quotes, cClass);
            filtNames_clean = strjoin(filtNames_clean, {','});
            isChar = strcmp(cClass, 'char');
            if isChar
                % For chars, set includeMissing to true as we do not want to filter for missing in codegen 
                includeMissing = true;
            end
            if includeMissing
                if (nFiltNames == 0)
                    % If there are no items that have been deselected (Entire list is checked)
                    filtCode = {[';']};
                    executionCode = {sprintf('tempDM = this.OrigData;')};
                elseif (nFiltNames == 1)
                    % If only 1 item has been deselected  (Only one items in list in UN-checked)
                    if internal.matlab.variableeditor.peer.PeerUtils.isStringOrCategoricalLike(cClass)
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' ~= ' filtNames_clean ',:);']};
                        executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                    elseif isChar 
                        % for single spaces, detect explicitly and generate
                        % isspace syntax for filtering
                        if isspace(filtNames{1})
                            filtCode = {[vName ' = ' vName '(~isspace(' vName '.' cName '),:);']};   
                            executionCode = {sprintf('tempDM = tempDM(~isspace(tempDM.%s),:);', cName)};
                        else
                            % For single chars, use ismember code for
                            % filtering (strcmp returns a scalar logical)
                            filtCode = {[vName ' = ' vName '(~ismember(' vName '.' cName ',' filtNames_clean '),:);']};
                            executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                        end
                    else
                        filtCode = {[vName ' = ' vName '(~strcmp(' vName '.' cName ',' filtNames_clean '),:);']};
                        executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s, %s),:);', cName, filtNames_clean)};
                    end
                else
                    % Detect if any of the filteredNames are spaces
                    if isChar
                        hasSpaces = cellfun(@isspace, filtNames);
                        % For combinations of spaces and char members,
                        % generate ismember | isspace code
                        if any(hasSpaces)
                            filtNamesWithoutSpace = filtNames(~hasSpaces);
                            filtNames_clean = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen(filtNamesWithoutSpace, quotes, cClass);
                            filtNames_clean = strjoin(filtNames_clean, {','});
                            filtCode = {[vName ' = ' vName '(~(ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c ') | isspace(' vName '.' cName ')),:);']};
                            executionCode = {sprintf('tempDM = tempDM(~(ismember(tempDM.%s,%s%s%s) | isspace(tempDM.%s)),:);', cName, ...
                                braces_o, filtNames_clean, braces_c, cName)};
                        else
                            filtCode = {[vName ' = ' vName '(~ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c '),:);']};
                            executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s,%s%s%s),:);', cName, ...
                                braces_o, filtNames_clean, braces_c)};
                        end
                    else
                        % If multiple items have been selected (More than 1 item in list is UN-checked)
                        filtCode = {[vName ' = ' vName '(~ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c '),:);']};
                        executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s,%s%s%s),:);', cName, ...
                            braces_o, filtNames_clean, braces_c)};
                    end

                end
            else
                if (nFiltNames == 0)
                    % If there are no items that have been deselected (Entire list is checked)
                    filtCode = {[vName ' = ' vName '(~ismissing(' vName '.' cName '),:);']};
                    executionCode = {sprintf('tempDM = tempDM(~ismissing(tempDM.%s),:);', cName)};
                elseif (nFiltNames == 1)
                    % If only 1 item has been deselected  (Only one items in list in UN-checked)
                    if internal.matlab.variableeditor.peer.PeerUtils.isStringOrCategoricalLike(cClass)
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' ~= ' filtNames_clean ' & ~ismissing(' vName '.' cName '),:);']};
                    else
                        filtCode = {[vName ' = ' vName '(~strcmp(' vName '.' cName ',' filtNames_clean ') & ~ismissing(' vName '.' cName '),:);']};
                    end
                    executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s, %s) & ~ismissing(tempDM.%s),:);', ...
                        cName, filtNames_clean, cName)};
                else
                    % If multiple items have been selected (More than 1 item in list is UN-checked)
                    filtCode = {[vName ' = ' vName '(~ismember(' vName '.' cName ',' braces_o filtNames_clean braces_c ') & ~ismissing(' vName '.' cName '),:);']};
                    executionCode = {sprintf('tempDM = tempDM(~ismember(tempDM.%s,%s%s%s) & ~ismissing(tempDM.%s),:);', ...
                        cName, braces_o, filtNames_clean, braces_c, cName)};
                end
            end
        end               
        
    end
end

