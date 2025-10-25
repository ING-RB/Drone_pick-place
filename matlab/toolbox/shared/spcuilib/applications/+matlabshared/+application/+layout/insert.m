function insert(parentLayout, dimension, index)
%INSERT inserts a row or a column in a uigridlayout at a given index.
%
% parentLayout - The parent uigridlayout which holds the ui component to be
%                inserted.
% dimension    - Charachter array from option 'row' or 'col' to insert a
%                new row or column respectively.
% index        - Desired row or column index. Default is one column greater
%                than the last row or column.

switch dimension
    case 'row'
        accessDimension = 'Row';
        accessSize = 'RowHeight';
    case {'col' 'column'}
        accessDimension = 'Column';
        accessSize = 'ColumnWidth';
end

% index defaults to the last element.
nIndices = numel(parentLayout.(accessSize));
if nargin < 3
    index = nIndices + 1;
end

% Increment Dimension
if index <= nIndices
    % Push elements after the insert ahead
    for j = 1:length(parentLayout.Children)
        fellowIndex = parentLayout.Children(j).Layout.(accessDimension);
        if fellowIndex >= index
            parentLayout.Children(j).Layout.(accessDimension) = fellowIndex + 1;
        end
    end
else
    parentLayout.(accessSize){end+1} = '1x';
end

% [EOF]
