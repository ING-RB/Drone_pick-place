% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

classdef OutputColumnClassStrategy < handle
    methods(Abstract = true)

        % Return the column classes for this output type, given the initial
        % column classes.   Return value columnClasses can be a scalar char
        % or string, which will be applied to every column (for example,
        % every column must be 'double'), or it can be a cell array,
        % matching the same size as the input initialColumnClasses.
        columnNames = getColumnClassesForImport(this, defaultColumnClasses);
    end
end