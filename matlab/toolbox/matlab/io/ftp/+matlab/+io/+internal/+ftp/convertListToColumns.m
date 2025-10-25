function list = convertListToColumns(list)

% Pad the list out with two extra spaces to separate the columns
    list = [list, ' '*ones(size(list,1), 2)];

    % Calculate the number of columns that fit on the screen
    windowWidth = get(0,'CommandWindowSize')*[1;0];
    numberOfColumns = floor(windowWidth/size(list,2));
    if (numberOfColumns == 0)
        numberOfColumns = 1;
    end

    % Calculate the number of rows and pad out the remaining column
    rows = ceil(size(list,1)/numberOfColumns);
    pad = rows * numberOfColumns-size(list,1);
    list = [list; ' '*ones(pad,size(list,2))];

    [r,c] = size(list);
    [I,J] = find(ones(rows,r*c/rows));
    ind = sub2ind(size(list), floor((J-1)/c)*rows+I, rem(J-1,c)+1);
    list = reshape(list(ind),rows,r*c/rows);
end