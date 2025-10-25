function indices = findElement(nestedCellArray, target)
    %findElement to find element from nested CellArray
    
    %   Copyright 2023 The MathWorks, Inc.
    
    indices = cell(0); % Initialize an empty cell array to store indices
    % Nested function for recursive search
    function search(cellArray, currentIndices)
        for i = 1:numel(cellArray)
            if iscell(cellArray{i})
                % If it's a cell array, recursively search inside it
                newIndices = [currentIndices, i];
                search(cellArray{i}, newIndices);
            else
                % If the current element is not a cell array, compare it to the target
                if isequal(cellArray{i}, target)
                    indices = [indices; [currentIndices, i]]; %#ok<AGROW>
                end
            end
        end
    end

    % Start the recursive search from the top-level nested cell array
    search(nestedCellArray, []);
end