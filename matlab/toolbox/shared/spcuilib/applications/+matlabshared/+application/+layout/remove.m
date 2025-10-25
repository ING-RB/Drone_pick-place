function remove(parentLayout, dimension, index)
%REMOVE removes a row or a column in a uigridlayout from a given index.
%
% parentLayout - The parent uigridlayout.
% dimension    - Dimension to remove either 'row' or 'col'
% index        - Desired row or column index to be removed.

switch dimension
    case 'row'
        accessDimension = 'Row';
        accessSize = 'RowHeight';
    case {'col' 'column'}
        accessDimension = 'Column';
        accessSize = 'ColumnWidth';
end

% Remove from layout any widgets on the row/col that is being removed.
children = parentLayout.Children;
for k = 1:length(children)
    if children(k).Layout.(accessDimension) == index
        children(k).Parent = [];
    end
end

% Decrement Dimension
if index <= numel(parentLayout.(accessSize))
    % Pull others later in the layout towards location
    for j = 1:length(children)
        fellowIndex = children(j).Layout.(accessDimension);
        if fellowIndex > index
            children(j).Layout.(accessDimension) = fellowIndex - 1;
        end
    end
else
    parentLayout.(accessSize){end+1} = '1x';
end

parentLayout.(accessSize)(index) = [];

% [EOF]
