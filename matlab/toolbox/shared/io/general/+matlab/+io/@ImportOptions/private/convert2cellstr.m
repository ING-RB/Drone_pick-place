function result = convert2cellstr(data)
result = data;
if ischar(data)
    % cannot use cellstr because it trims trailing whitespace
    % characters from character arrays.
    numrows = size(data,1);
    result = cell(numrows,1);
    for i = 1:numrows
        result{i} = data(i,:);
    end
elseif isstring(data)
    % cellstr does not trim trailing whitespace characters
    % if the input character is a string array.
    result = cellstr(data);
end
end

% Copyright 2016-2023 The MathWorks, Inc.