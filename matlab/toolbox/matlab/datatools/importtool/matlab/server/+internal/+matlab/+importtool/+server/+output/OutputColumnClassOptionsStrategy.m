% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

classdef OutputColumnClassOptionsStrategy < handle
    methods(Abstract = true)

        % Return the column class options for this output type, given the
        % initial column classes.  Return value columnClassOptions should be the
        % same size as the defaultColClassOptions.
        columnClassOptions = getColumnClassOptionsForImport(this, initialColumnClassOptions);
    end
end