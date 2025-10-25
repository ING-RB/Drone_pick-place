function missingRows = getMissingRows(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    missingRows = obj.counts < obj.numColumns;
end
