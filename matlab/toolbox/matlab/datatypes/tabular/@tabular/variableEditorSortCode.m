function [sortCode,msg] = variableEditorSortCode(t,varName,tableVariableNames,direction, missingPlacement)
    arguments
        t
        varName
        tableVariableNames
        direction
        missingPlacement  {mustBeMember(missingPlacement,["auto","first","last"])} = "auto"
    end
    % This function is for internal use only and will change in a
    % future release.  Do not use this function.
    
    % Generate MATLAB command to sort table rows. The direction input
    % is true for ascending sorts, false otherwise.
    
    %   Copyright 2011-2021 The MathWorks, Inc.
    
    msg = '';
    
    colNames = variableEditorColumnNames(t);
    if isdatetime(t.rowDim.labels) || isduration(t.rowDim.labels)
        % The first column is the row labels dimension, but this shouldn't be taken
        % into account in the column indexing, so remove it.
        colNames(1) = [];
    end
    if ~iscell(tableVariableNames)
        tableVariableNames = {tableVariableNames};
    end
   
    allVarNames = all(cellfun(@isvarname, tableVariableNames));
    includesRowDim = any(strcmp(t.metaDim.labels{1}, tableVariableNames));
    separateCmd = '';
    separateCmdIdx = 0;
    if length(tableVariableNames) > 1
        cmds = strings(0);
        for k=1:length(tableVariableNames)
            [s, sIdx] = getVarNameAndIndex(k);
            if allVarNames
                % If all the variables being sorted are valid MATLAB
                % identifiers, then use them in the command
                cmds(end + 1) = s; %#ok<*AGROW>
            else
                % At least one of the variables being sorted is not a valid
                % MATLAB identifier, so use the index for sorting.  If also
                % including the time column for timetables, take extra steps to
                % include it as a separate command
                if includesRowDim && (isempty(s) || isempty(sIdx))
                    if ~isempty(s)
                        separateCmd = s;
                    else
                        separateCmd = sIdx;
                    end
                    separateCmdIdx = k;
                else
                    cmds(end + 1) = sIdx;
                end
            end
        end
        
        if allVarNames
            tableVariableNameString = char("[" + join(cmds, ",") + "]");
        else
            tableVariableIndexString = char("[" + join(cmds, ",") + "]");
        end
    else
        % Sorting by a single column
        [tableVariableNameString, tableVariableIndexString] = getVarNameAndIndex(1);
    end
    
    if direction
        directionText = 'ascend';
    else
        directionText = 'descend';
    end
    missingPlacementSyntax = '';
    if ~strcmp(missingPlacement, "auto")
        missingPlacementSyntax = [',"MissingPlacement","' char(missingPlacement) '"'];
    end
    if allVarNames
        % Use the variable name in the command, like: sortrows(t,'A','ascend');
        sortCode = [varName ' = sortrows(' varName ',' tableVariableNameString ',"' directionText '"' missingPlacementSyntax ');'];
    else
        % Use the variable index in the command, like: sortrows(t,1,'ascend');
        sortCode = '';
        if ~isempty(separateCmd) && separateCmdIdx == 1
            % String together separate commands when needed, such as when a
            % timetable column and a column with an arbitrary var name is
            % selected to sort together, we need something like:
            % t = sortrows(t,'Time','ascend'); t = sortrows(t,2,'ascend');
            sortCode = [varName ' = sortrows(' varName ',' separateCmd ',"' directionText '"' missingPlacementSyntax '); '];
        end
        sortCode = [sortCode varName ' = sortrows(' varName ',' tableVariableIndexString ',"' directionText '"' missingPlacementSyntax ');'];
        if ~isempty(separateCmd) && separateCmdIdx > 1
            % Add in the separate command after the other column indices
            sortCode = [sortCode ' ' varName ' = sortrows(' varName ',' separateCmd ',"' directionText '"' missingPlacementSyntax ');'];
        end
    end

    
    function [tableVariableNameString, tableVariableIndexString] = getVarNameAndIndex(varIdx)
        idx = find(matches(colNames, tableVariableNames{varIdx}));
        if isempty(idx) && strcmp(t.metaDim.labels{1}, tableVariableNames{varIdx})
            if isvarname(t.metaDim.labels{1})
                % Use the Time column dimension name for sorting
                tableVariableIndexString = '';
                tableVariableNameString = ['"' t.metaDim.labels{1} '"'];
            else
                % The Time column dimension is an arbitrary variable name, so
                % reference it through the properties DimensionNames
                tableVariableIndexString = [varName '.Properties.DimensionNames{1}'];
                tableVariableNameString = '';
            end
        else
            tableVariableIndexString = num2str(idx);
            tableVariableNameString = ['"' colNames{idx} '"'];
        end
    end
end


