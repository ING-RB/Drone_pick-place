% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2020-2023 The MathWorks, Inc.
classdef BaseTypesVariableEditorAdapter
    
    methods(Static=true)
        
        % Generates matlab command to insert column to the left of the
        % current colSelection indices in array 'a' with variableName 'varName'. 
        % emptyValCommand will be command to be used as filler to fill the 
        % cells of the newly created column.
        % Returns currentCols as well that contains shifted column indices to be
        % updated post insert operation. 
        % eg: cell/zeros.
        function [cmd, warning, currentCols] = insertColumnToLeftCode(a, varName, colSelection, emptyValCmd)
            cmd = '[';
            warning = '';
            lastCol = nan;
            currentCols = [];
            currentColLen = 0;
            aLen = size(a);
            for col = colSelection'
                uCol = unique(col);
                if uCol(1) - 1 > 0
                    colStr = sprintf('%d:%d', max(1, lastCol), min(aLen(2), uCol(1) - 1));
                    cmd = [cmd sprintf('%s(:,%s)', varName, colStr) ' '];
                end
                uColLen = length(uCol);
                if isscalar(uCol)
                    currentCol = uCol + (currentColLen + uColLen);                    
                    newCols = [currentCol currentCol];                    
                else
                    uColLen = length(uCol(1): uCol(2));
                    newCols = [uCol(1) uCol(2)] + (currentColLen + uColLen);
                end
                if uCol(1) <= aLen(2)
                    currentCols = [currentCols; newCols];
                end
                currentColLen = currentColLen + uColLen;
                lastCol = uCol(1);
                cmd = [cmd sprintf('%s(%d,%d)', emptyValCmd, height(a), uColLen) ' '];
            end
            % If lastCol exceeds size, the lastIndexing of the variable is not required.
            if lastCol <= aLen(2)
               cmd = [cmd sprintf('%s(:,%d:end)', varName, lastCol)]; 
            else
                cmd = strtrim(cmd);
            end
            cmd = sprintf('%s = %s;',varName, [cmd ']']);
        end
        
        % Generates matlab command to insert column to the right of the
        % current colSelection indices in array 'a' with variableName 'varName'. 
        % emptyValCommand will be command to be used as filler to fill the 
        % cells of the newly created column.
        % Returns currentCols as well that contains shifted column indices to be
        % updated post insert operation. 
        % eg: cell/zeros.
        function [cmd, warning, currentCols] = insertColumnToRightCode(a, varName, colSelection, emptyValCmd)
            cmd = '[';
            warning = '';
            prevCol = 1;
            currentCols = [];
            currentColLen = 0;
            aLen = size(a);
            for col=colSelection'
                uCol = unique(col);
                index = uCol;
                uColLen = length(uCol);
                if ~isscalar(uCol)
                   index = uCol(2);
                   uColLen = length(uCol(1):uCol(2));                
                   currentCols = [currentCols; [uCol(1) uCol(2)] + currentColLen];
                else
                   currentCol = uCol + currentColLen;
                   currentCols = [currentCols; [currentCol currentCol]]; 
                end
                currentColLen = currentColLen + uColLen;
                colStr = sprintf('%d:%d', prevCol, min(aLen(2), index));
                prevCol = index + 1;
                cmd = [cmd sprintf('%s(:,%s)', varName, colStr) ' '];
                % If index is beyond data bounds, fill with emptyVal upto selection boundary
                if index > aLen(2)
                    uColLen = uColLen + (index - aLen(2));
                end
                cmd = [cmd sprintf('%s(%d,%d)', emptyValCmd, height(a), uColLen) ' '];
            end
            if prevCol <= length(a)
                cmd = [cmd sprintf('%s(:,%d:end)', varName, min(length(a), prevCol))];
            end
            cmd = sprintf('%s = %s;',varName, [strtrim(cmd) ']']);
        end
        
        % Generates matlab command to insert row above the
        % current rowSelection indices in array 'a' with variableName 'varName'. 
        % emptyValCommand will be command to be used as filler to fill the 
        % cells of the newly created row(s).
        % Returns currentRows as well that contains shifted row indices to be
        % updated post insert operation. 
        % eg: cell/zeros.
        function [cmd, warning, currentRows] = insertRowAboveCode(a, varName, rowSelection, emptyValCmd)
            cmd = 'vertcat(';
            warning = '';
            lastRow = nan;
            currentRows = [];
            currentRowLen = 0;
            aLen = size(a);
            for row = rowSelection'
                uRow = unique(row);
                uRowLen = length(uRow);
                if uRow(1) - 1 > 0
                    rowStr = sprintf('%d:%d', max(1, lastRow), min(aLen(1), uRow(1) - 1));
                    cmd = [cmd sprintf('%s(%s,:)', varName, rowStr) ', '];
                end
                
               if isscalar(uRow)
                    currentRow = uRow + (currentRowLen + uRowLen);
                    newRows = [currentRow currentRow];
                else
                    uRowLen = length(uRow(1): uRow(2));
                    newRows = [uRow(1) uRow(2)] + (currentRowLen + uRowLen);
               end 
                if uRow(1) <= aLen(1)
                    currentRows = [currentRows; newRows];
                end
                currentRowLen = currentRowLen + uRowLen;
                lastRow = uRow(1);
                cmd = [cmd sprintf('%s(%d,%d)', emptyValCmd, uRowLen , width(a)) ', '];
            end
            % If lastCol exceeds size, the lastIndexing of the variable is not required.
            if lastRow <= aLen(1)
               cmd = [cmd sprintf('%s(%d:end,:)', varName, lastRow)]; 
            else
                cmd = cmd(1:end-2);
            end
            cmd = sprintf('%s = %s;',varName, [cmd ')']);
        end
        
        % Generates matlab command to insert row below the
        % current rowSelection indices in array 'a' with variableName 'varName'. 
        % emptyValCommand will be command to be used as filler to fill the 
        % cells of the newly created row(s).
        % Returns currentRows as well that contains shifted row indices to be
        % updated post insert operation.
        % eg: cell/zeros.
        function [cmd, warning, currentRows] = insertRowBelowCode(a, varName, rowSelection, emptyValCmd)
            cmd = 'vertcat(';
            warning = '';
            prevRow = nan;
            currentRows = [];
            currentRowLen = 0;
            aLen = size(a);
            for row = rowSelection'
                uRow = unique(row);
                index = uRow;
                uRowLen = length(uRow);

                if ~isscalar(uRow)
                    index = uRow(2);
                    uRowLen = length(uRow(1): uRow(2));
                    currentRows = [currentRows; [uRow(1) uRow(2)] + currentRowLen];
                else
                    currentRow = uRow + currentRowLen;
                    currentRows = [currentRows; [currentRow currentRow]]; 
                end
                
                currentRowLen = currentRowLen + uRowLen;
                rowStr = sprintf('%d:%d', max(1, prevRow), min(aLen(1), index));
                cmd = [cmd sprintf('%s(%s,:)', varName, rowStr) ', '];
                % If index is beyond data bounds, fill with emptyVal upto selection boundary
                if index > aLen(1)
                    uRowLen = uRowLen + (index - aLen(1));
                end
                cmd = [cmd sprintf('%s(%d,%d)', emptyValCmd, uRowLen, width(a)) ', '];
                prevRow = index + 1;
            end
            if prevRow <= length(a)
                cmd = [cmd sprintf('%s(%d:end,:)', varName, prevRow)];
            else
                cmd(end-1) = '';% Remove any trailing commas
            end
            cmd = sprintf('%s = %s;',varName, [strtrim(cmd) ')']);
        end
        
        % Generates transpose code for the given variable name.
        % User operator ' for generating code, for complex conjugates, x=x'
        % would do the right transpose operation.
        function [out, warning] = variableEditorTransposeCode(varName)
            warning = '';
            out = sprintf('%s = %s'';', varName, varName);
        end
           
        % Generates column delete code to delete the columns specified by
        % the colIntervals for numeric/cell arrays.       
        function [out, warnmsg] = variableEditorColumnDeleteCode(a, ...
                varName, colIntervals)
            % Generate MATLAB command to delete columns positions defined
            % by the 2-column colIntervals matrix. It is assumed that
            % column intervals are disjoint,  in monotonic order,  and
            % bounded by the number of columns in the variable
            % array.
            warnmsg = '';
            if size(colIntervals,1)==1
                s = size(a);
                if s(1,1) == 1
                    out = sprintf('%s(%s) = [];', varName, ...
                        localBuildSubsref(colIntervals(1), colIntervals(2)));
                else
                    out = sprintf('%s(:,%s) = [];', varName, ...
                        localBuildSubsref(colIntervals(1), colIntervals(2)));
                end
            else
                columnSubsref = localBuildSubsref(colIntervals(1,1), ...
                    colIntervals(1,2));
                for row=2:size(colIntervals,1)
                    columnSubsref = sprintf('%s,%s', columnSubsref, ...
                        localBuildSubsref(colIntervals(row,1), ...
                        colIntervals(row,2)));
                end
                % e.g. x(:, [1:2 5]) = [];
                out = sprintf('%s(:,[%s]) = [];', varName, columnSubsref);
            end
        end
        
        % Generates column delete code to delete the rows specified by
        % the rowIntervals for numeric/cell arrays.
        function [out, warnmsg] = variableEditorRowDeleteCode(a, ...
                varName, rowIntervals)
            % Generate MATLAB command to delete rows in positions defined
            % by the 2-column rowIntervals matrix. It is assumed that row
            % intervals are disjoint, in monotonic order, and bounded by
            % the number of rows in the array.
            warnmsg = '';
            
            if size(rowIntervals,1)==1
                s = size(a);
                if s(1,2) == 1
                    out = sprintf('%s(%s) = [];', varName, localBuildSubsref(...
                        rowIntervals(1), rowIntervals(2)));
                else
                    out = sprintf('%s(%s,:) = [];', varName, localBuildSubsref(...
                        rowIntervals(1), rowIntervals(2)));
                end
            else
                rowSubsref = localBuildSubsref(rowIntervals(1,1), ...
                    rowIntervals(1,2));
                for row=2:size(rowIntervals, 1)
                    rowSubsref = sprintf('%s,%s', rowSubsref, localBuildSubsref(...
                        rowIntervals(row,1), rowIntervals(row, 2)));
                end
                % e.g. x([1:2 5],:) = [];
                out = sprintf('%s([%s],:) = [];', varName, rowSubsref);
            end
        end
        
        function [out,warnmsg] = variableEditorSortCode(data, varName, ...
                columnIndexStrings, direction, slice, missingPlacement)
            % Generate MATLAB command to sort numeric/cell rows. The direction
            % input is true for ascending sorts, false otherwise.
            warnmsg = '';
            % Generate code for sorting
            lhsVarname = varName;
            rhsVarname = varName;

            if ~ismatrix(data)
                lhsVarname = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.getNDActionName(data, varName, slice, false);
                rhsVarname = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.getNDActionName(data, varName, slice, true);
            end
            missingPlacementSyntax = "";
            if ~strcmp(missingPlacement, "auto") && ~iscell(data)
                missingPlacementSyntax = ", ""MissingPlacement"", """ + missingPlacement + """";
            end
            if direction
                out = lhsVarname + " = sortrows(" + rhsVarname + "," ...
                    + columnIndexStrings + missingPlacementSyntax + ");";
            else
                out = lhsVarname + " = sortrows(" + rhsVarname + "," ...
                    + columnIndexStrings + ", ""descend""" + missingPlacementSyntax + ");";
            end
        end

        function name = getNDActionName(data, varName, slice, isRHS)
            name = varName;
            if ~ismatrix(data)
                name = sprintf("%s(" + strjoin(slice,",") + ")", varName);
                if isRHS
                    sliceDimIndices = find(slice == ":");
                    if ~isequal(sliceDimIndices,[1 2])
                        % When not indexing the first two dimensions you'll
                        % get a mxnx1 and need squeeze to get rid of the x1
                        % dimenion
                        name = sprintf("squeeze(%s)", name);
                    end
                end
                name = string(name);
            end
        end
        
        function name = getNDSelection(data, varName, slice, rows, cols)
            name = varName;
            if ~ismatrix(data)
                name = sprintf("%s(" + strjoin(slice,",") + ")", varName);
                if isRHS
                    sliceDimIndices = find(slice == ":");
                    if ~isequal(sliceDimIndices,[1 2])
                        % When not indexing the first two dimensions you'll
                        % get a mxnx1 and need squeeze to get rid of the x1
                        % dimenion
                        name = sprintf("squeeze(%s)", name);
                    end
                end
                name = string(name);
            end
        end

        % Returns cmd to replace current selection with empty (''|[]|0) for
        % tabular types. TODO: Move to ReplaceEmpty action
        function cmd = variableEditorClearTableCode(data, varname, rows, cols, gcolCounts)
             rowStr = internal.matlab.variableeditor.BlockSelectionModel.getRangeStr(rows);
             cmd = "";
             for col = cols.'
                 actualStart = col(1);
                 actualEnd = col(2);
                 if ~isempty(gcolCounts)
                     [actualStart, actualEnd] = internal.matlab.variableeditor.TableViewModel.getNestedColumnRange(col(1), col(2), gcolCounts);
                 end
                 for i=actualStart:actualEnd
                     if (~isempty(gcolCounts) && gcolCounts(i) > 1)
                         colStr = internal.matlab.variableeditor.TableViewModel.getColumnSubstringForGroupedCol(col(1), col(2),i, gcolCounts);
                         [out, warnmsg] = variableEditorReplaceWithEmptyCode(data, varname, rows, i, rowStr, colStr);
                     else
                        [out, warnmsg] = variableEditorReplaceWithEmptyCode(data, varname, rows, i, rowStr, []);
                     end
                     if isempty(warnmsg)
                         cmd = cmd + out;
                     end
                 end
             end
        end
        
        % generates code to clear Variable Editor code for the given 
        % row and column intervals. 
        % API takes in incoming replacement Value. If no value is
        % specified, For Numerics, we replace 0 in the
        % cleared intervals and for cell arrays, we replace by []
        function [out, warnmsg] = variableEditorClearDataCode(a, ...
                varName, rowIntervals, colIntervals, replacement, slice)
            arguments
                a 
                varName;
                rowIntervals double;
                colIntervals double;
                replacement = '0';
                slice = '';
            end
            % Generates the MATLAB command to delete the content specified
            % by the rowIntervals and colIntervals of the string
            % variable.
            warnmsg = '';
            
            rowSubsref = localBuildSubsrefWithLen(rowIntervals(1,1), ...
                rowIntervals(1,2), size(a,1));
            for row=2:size(rowIntervals, 1)
                rowSubsref = sprintf('%s,%s', rowSubsref,...
                    localBuildSubsrefWithLen(rowIntervals(row,1), ...
                    rowIntervals(row,2), size(a,1)));
            end
            if size(rowIntervals,1)>1 % Multiple intervals need to be wrapped in []
                rowSubsref = sprintf('[%s]', rowSubsref);
            end
            
            colSubsref = localBuildSubsrefWithLen(colIntervals(1,1), ...
                colIntervals(1,2), size(a,2));
            for col=2:size(colIntervals,1)
                colSubsref = sprintf('%s,%s', colSubsref, ...
                    localBuildSubsrefWithLen(colIntervals(col,1), ...
                    colIntervals(col,2), size(a,2)));
            end
            if size(colIntervals,1)>1
                colSubsref = sprintf('[%s]', colSubsref);
            end
            
            % Generate code to clear the range, by setting the value to 0
            % for numerics and logicals and to {[]} for cell arrays
            if iscell(a)
                replacement = '{[]}';
            end
            if ~isempty(slice)
                sliceDimIndices = find(slice == ":");
                formatStr = "%s(" + strjoin(slice,",").replace(":","%s") + ") = %s;";
                out = sprintf(formatStr, varName, rowSubsref, colSubsref, replacement);
            else
                out = sprintf('%s(%s,%s) = %s;', varName, ...
                    rowSubsref, colSubsref, replacement);
            end
        end
    end
end

function subsrefexp = localBuildSubsref(startCol, endCol)  
    % Create a sub-index expression for the interval startCol:endCol
    if startCol == endCol
        subsrefexp = sprintf('%d', startCol);
    else
        subsrefexp = sprintf('%d:%d', startCol, endCol);
    end
end

function subsrefexp = localBuildSubsrefWithLen(startIndex, endIndex, len) 
    % Create a sub-index expression for the interval startCol:endCol
    if startIndex == 1 && endIndex >= len
        subsrefexp = ':';
    elseif startIndex == endIndex
        subsrefexp = sprintf('%d', startIndex);
    else
        subsrefexp = sprintf('%d:%d', startIndex, endIndex);
    end
end


