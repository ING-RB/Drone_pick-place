function varData = getVarOrRowLabelData(t,varIndices,wmsgid) %#codegen
% Return the specified data vars and/or the row labels, wrapped up in a cell
% array. A var index of 0 indicates row labels. This is useful for collecting up
% sorting/grouping vars in methods like sortrows or varfun, but is not needed
% where only data vars are legal, e.g. InputVariables in varfun.

%   Copyright 2020 The MathWorks, Inc.

isRowLabels = (varIndices == 0);
if any(isRowLabels)
    if t.rowDim.hasLabels
        rowLabels = t.rowDim.labels;
    else
        % If there _are_ no row labels, warn and use the row indices.
        % Timetable row times are required, this can only happen for
        % tables. Error if a caller ends up here, has no row labels, and
        % has not provided a warning id.
        coder.internal.warning(wmsgid);
        rowLabels = (1:t.rowDim.length)';
    end
    if isscalar(varIndices)
        % If it's only the row labels, return quickly.
        varData = { rowLabels };
        return
    end
    
    varData = cell(1,length(varIndices));
    for i = 1:length(isRowLabels)
        if isRowLabels(i)
            varData{i} = rowLabels;
        else
            varData{i} = t.data{varIndices(i)};
        end
    end
else
    varData = cell(1,length(varIndices));
    for i = 1:length(varIndices)
        varData{i} = t.data{varIndices(i)};
    end
end
