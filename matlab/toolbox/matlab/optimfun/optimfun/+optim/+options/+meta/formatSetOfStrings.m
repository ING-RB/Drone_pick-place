function formattedList = formatSetOfStrings(stringsIn)
%formatSetOfStrings combine a cell of char vectors into a comma separated
%list including a conjunction if needed.

%   Copyright 2019 The MathWorks, Inc.

% Add quotes around each string in the array, with a comma and space after
allstrings = "'" + string(stringsIn) + "', ";

% If the list is not a single value, add the "or" to the final element and
% remove the unneeded last comma
numStrings = numel(allstrings);
if numStrings >= 2
    finalConjunction = "or ";
else
    finalConjunction = "";
end
allstrings(end) = finalConjunction + extractBefore(allstrings(end), ",");

% Make into a single string
formattedList = char(join(allstrings));
end