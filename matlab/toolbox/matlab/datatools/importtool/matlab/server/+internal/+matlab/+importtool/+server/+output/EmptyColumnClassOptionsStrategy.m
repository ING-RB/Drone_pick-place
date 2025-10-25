% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

classdef EmptyColumnClassOptionsStrategy < internal.matlab.importtool.server.output.OutputColumnClassOptionsStrategy
    methods
        function this = EmptyColumnClassOptionsStrategy()
        end
        
        function columnClassOptions = getColumnClassOptionsForImport(~, defaultColClassOptions)
            columnClassOptions = repmat({''}, size(defaultColClassOptions));
        end
    end
end