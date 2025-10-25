classdef HeaderMenuStateHandler < handle
    % Class that handles the state updates to the Header Menu UI

    % Copyright 2018 The MathWorks, Inc.
    
    properties(Constant)
        ViewportStartRow = 0;
        ViewportEndRow = 15;
        ViewportStartColumn = 0;
        ViewportEndColumn = 2;
    end
    
    
     methods(Static, Access='public')
        % update menu state
        % returns a cell array of strings for the desired range of values
        function updateHeaderMenu(mgr, colName, dataRange)
            columns = dataRange.get('columns');
            rows = dataRange.get('rows');
            startColumn = columns.get('start');
            endColumn = columns.get('end');
            startRow = rows.get('start');
            endRow = rows.get('end');
            doc = internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.getDocumentFromManager(mgr, colName);
            doc.ViewModel.updateRowModelInformation(startRow + 1, endRow + 1);
            doc.ViewModel.refreshRenderedData(struct('startRow', startRow ,'endRow', endRow, 'startColumn', startColumn, 'endColumn', endColumn));
        end
        
        function updateHeaderMenuForUndo(mgr, tws, sh)
            if (sh.CommandArray(end).Command == "Filter")
                % Since we are undoing a filtering operation, we know that
                % will need to undo the UI selections as well.
                
                %First we need to find the last filter command to undo upto
                undoFilter = sh.CommandArray(end);
                
                % Check the number of filters that have been applied to the
                % Column on which the undo operation is happening
                filtIdx = find([sh.CommandArray(1:end).Index] == undoFilter.Index);
                colFiltCount =  numel(filtIdx);

                if (colFiltCount == 1)
                    % If filter being removed is the only filter applied to
                    % that column, reset the selection state to default
                    colName = sh.DataModel.Data.Properties.VariableNames{undoFilter.Index};
                    % Number of columns in the table will help us indentify
                    % the class
                    if (size(tws.(colName),2) == 3)
                        tws.(['unsearched_' num2str(undoFilter.Index)]).Selected(:) = true;
                    elseif contains('SelectedRangeMin', tws.(colName).Properties.VariableNames)
                        tws.clearNumericRange(colName, false);
                        tws.(colName).IncludeMissing(:) = true;
                    end
                else
                    undoFilter = sh.CommandArray(filtIdx(end-1));
                    colName = sh.DataModel.Data.Properties.VariableNames{undoFilter.Index};
                    
                    if (size(tws.(colName),2) == 3)
                        tws.(colName).Selected = undoFilter.commandInfo;
                        tws.(['unsearched_' num2str(undoFilter.Index)]).Selected = undoFilter.commandInfo;
                    elseif contains('SelectedRangeMin', tws.(colName).Properties.VariableNames)
                        tws.setNumericRange(colName, undoFilter.commandInfo.minVal, undoFilter.commandInfo.maxVal, false);
                        tws.(colName).IncludeMissing(:) = undoFilter.commandInfo.missingFlag;
                    end
                end
                % Update the client view
                internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.updateClientForUndoRedo(mgr, colName);
            elseif sh.isBoundaryCondition(sh.CommandArray(end))  
                % If we are undoing a boundary condition, fetch all the
                % filtering conditions until the previous boundary
                % conditions, fetch their filtering commandInfo and restore
                % the state of the filtering workspace.
                boundaryConditionIndices = find(arrayfun(@(x)sh.isBoundaryCondition(x), sh.CommandArray));
                filterCommandIndices = find(arrayfun(@(x)strcmp(x.Command, 'Filter'), sh.CommandArray));
                filterIndicesBetweenBoundary = [];
                if (numel(boundaryConditionIndices)>1)
                    filterIndicesBetweenBoundary = arrayfun(@(x)x>boundaryConditionIndices(end-1) && x<boundaryConditionIndices(end), filterCommandIndices);
                elseif (numel(boundaryConditionIndices)==1)                    
                    filterIndicesBetweenBoundary = arrayfun(@(x)x<boundaryConditionIndices(end), filterCommandIndices);
                end 
                filterCommands = filterCommandIndices(filterIndicesBetweenBoundary);
                if ~isempty(filterCommands)                    
                    for i=1: length(filterCommands)
                        index = filterCommands(i);
                        filterCommand = sh.CommandArray(index);                                    
                        filtercolName = sh.DataModel.Data.Properties.VariableNames{filterCommand.Index};

                        if (size(tws.(filtercolName),2) == 3)
                            tws.(filtercolName).Selected = filterCommand.commandInfo;
                            tws.(['unsearched_' num2str(filterCommand.Index)]).Selected = filterCommand.commandInfo;
                        elseif contains('SelectedRangeMin', tws.(filtercolName).Properties.VariableNames)
                            tws.setNumericRange(filtercolName, filterCommand.commandInfo.minVal, filterCommand.commandInfo.maxVal, false);
                            tws.(filtercolName).IncludeMissing(:) = filterCommand.commandInfo.missingFlag;
                        end
                        % Update the client view
                        internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.updateClientForUndoRedo(mgr, filtercolName);                        
                    end
                    
                end
            end                         
        end
        
        function updateHeaderMenuForRedo(mgr, tws, sh)
            if ( sh.UndoCommandArray(end).Command == "Filter")
                % Since we are undoing a filtering operation, we know that
                % will need to undo the UI selections as well.
                
                % First we need to find the last filter command to undo upto
                redoFilter = sh.UndoCommandArray(end);
                
                % Perform the redo operation
                index = sh.UndoCommandArray(end).Index;
                colName = sh.DataModel.Data.Properties.VariableNames{index};
                if (size(tws.(colName),2) == 3)
                    tws.(['unsearched_' num2str(index)]).Selected = redoFilter.commandInfo;
                elseif contains('SelectedRangeMin', tws.(colName).Properties.VariableNames)
                    tws.setNumericRange(colName, redoFilter.commandInfo.minVal, redoFilter.commandInfo.maxVal, false);
                    tws.(colName).IncludeMissing(:) = redoFilter.commandInfo.missingFlag;
                end
                % Update the client view
                internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.updateClientForUndoRedo(mgr, colName);               
            end
        end
        
        function doc = getDocumentFromManager(mgr, colName)
            docNames = arrayfun(@(x) x.Name, mgr.Documents, 'UniformOutput', false);
            doc = mgr.Documents(find(strcmp(docNames, colName)));
        end
        
        function updateClientForUndoRedo(mgr, colName)
            import internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler;
            doc = HeaderMenuStateHandler.getDocumentFromManager(mgr, colName);
            if ~isempty(doc)
                doc.ViewModel.refreshRenderedData(struct('startRow', HeaderMenuStateHandler.ViewportStartRow ,'endRow', HeaderMenuStateHandler.ViewportEndRow, ...
                'startColumn', HeaderMenuStateHandler.ViewportStartColumn, 'endColumn', HeaderMenuStateHandler.ViewportEndColumn));
            end            
        end        
     end
end
