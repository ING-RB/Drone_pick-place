% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

classdef OutputColumnNameStrategy < handle
    methods(Abstract = true)

        % Return the column names for this output type, given the default column
        % names.  The return values will be the same length as the
        % defaultColumnNames argument.
        columnNames = getColumnNamesForImport(this, defaultColumnNames);
    end
end