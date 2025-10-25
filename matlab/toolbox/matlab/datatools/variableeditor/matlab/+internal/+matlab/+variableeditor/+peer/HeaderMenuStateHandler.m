classdef HeaderMenuStateHandler < handle
    % Class that handles the state updates to the Header Menu UI

    % Copyright 2018-2023 The MathWorks, Inc.

    properties(Constant)
        ViewportStartRow = 1;
        ViewportEndRow = 16;
        ViewportStartColumn = 1;
        ViewportEndColumn = 3;
    end


     methods(Static, Access='public')
         
        function refreshView(viewModel, startRow, endRow, startColumn, endColumn, sizeChanged)
            if (nargin < 6)
                sizeChanged = false;
            end
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = startRow;
            eventdata.StartColumn = startColumn;
            eventdata.EndRow = endRow;
            eventdata.EndColumn = endColumn;
            eventdata.SizeChanged = sizeChanged;
            viewModel.notify('DataChange', eventdata);
        end
                 
        % update menu state
        % returns a cell array of strings for the desired range of values
        function updateHeaderMenuForViewport(mgr, colName)           
            doc = internal.matlab.variableeditor.peer.HeaderMenuStateHandler.getDocumentFromManager(mgr, colName);
            if ~isempty(doc)
                headerViewModel = doc.ViewModel;
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshView(...
                    headerViewModel, headerViewModel.ViewportStartRow, headerViewModel.ViewportEndRow, ...
                    headerViewModel.ViewportStartColumn, headerViewModel.ViewportEndColumn);
            end
        end
        
        function updateHeaderMenu(mgr, colName)
            doc = internal.matlab.variableeditor.peer.HeaderMenuStateHandler.getDocumentFromManager(mgr, colName);
            dataSize = doc.ViewModel.getTabularDataSize();
            internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshView(...
                doc.ViewModel, 1, dataSize(1), 1, dataSize(2));
        end  
        
        
        % Clear buffer and update viewportdata for all the views of the
        % manager.
        function refreshViews(mgr)
            docs = mgr.Documents;            
            for i=1:length(docs)
                filteredViewModel = docs(i).ViewModel;
                dataSize = filteredViewModel.getTabularDataSize();
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshView(...
                filteredViewModel, 1, dataSize(1), 1, dataSize(2));
            end
        end

        function updateHeaderMenuForUndo(mgr, tws, sh)
            if (sh.CommandArray(end).Command == "Filter")
                % Since we are undoing a filtering operation, we know that
                % will need to undo the UI selections as well.

                %First we need to find the last filter command to undo upto
                undoFilter = sh.CommandArray(end);

                % Check the number of filters that have been applied to the
                % Column on which the undo operation is happening
                % g2068366: Get the subset of commands that are filtering and use
                % only those
                filterCommands = [sh.CommandArray(1:end).Command] == "Filter";
                filtIdx = find([sh.CommandArray(filterCommands).Index] == undoFilter.Index);
                colFiltCount =  numel(filtIdx);

                if (colFiltCount == 1)
                    % If filter being removed is the only filter applied to
                    % that column, reset the selection state to default
                    colName = sh.ViewModel.getHeaderInfoFromIndex(undoFilter.Index);
                    % Number of columns in the table will help us indentify
                    % the class
                    if (size(tws.(colName),2) == 3)
                        tws.(['unsearched_' num2str(undoFilter.Index)]).Selected(:) = true;
                    elseif contains('SelectedRangeMin', tws.(colName).Properties.VariableNames)
                        tws.clearNumericRange(colName, false);
                        tws.(colName).IncludeMissing(:) = true;
                    end
                else
                    filterCommandArray = sh.CommandArray(filterCommands);
                    % g2068366: The undo filter is the last filtering command
                    % which we can get from the is a subset of all commands.
                    undoFilter = filterCommandArray(filtIdx(end-1));
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
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateClientForUndoRedo(mgr, colName);
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
                colName = sh.ViewModel.getHeaderInfoFromIndex(index);
                if (size(tws.(colName),2) == 3)
                    tws.(['unsearched_' num2str(index)]).Selected = redoFilter.commandInfo;
                elseif contains('SelectedRangeMin', tws.(colName).Properties.VariableNames)
                    tws.setNumericRange(colName, redoFilter.commandInfo.minVal, redoFilter.commandInfo.maxVal, false);
                    tws.(colName).IncludeMissing(:) = redoFilter.commandInfo.missingFlag;
                end
                % Update the client view
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateClientForUndoRedo(mgr, colName);
            end
        end

        function doc = getDocumentFromManager(mgr, colName)
            docNames = arrayfun(@(x) x.Name, mgr.Documents, 'UniformOutput', false);
            doc = mgr.Documents(find(strcmp(docNames, colName)));
        end

        function updateClientForUndoRedo(mgr, colName)
            import internal.matlab.variableeditor.peer.HeaderMenuStateHandler;
            doc = HeaderMenuStateHandler.getDocumentFromManager(mgr, colName);
            if ~isempty(doc)
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshView(...
                doc.ViewModel, HeaderMenuStateHandler.ViewportStartRow, HeaderMenuStateHandler.ViewportEndRow, ...
                HeaderMenuStateHandler.ViewportStartColumn, HeaderMenuStateHandler.ViewportEndColumn);           
            end
        end
     end
end
