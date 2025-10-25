% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

classdef SingleOutputColumnClassStrategy < internal.matlab.importtool.server.output.OutputColumnClassStrategy
    properties
        ClassName string = strings(0);
    end
    
    methods
        function this = SingleOutputColumnClassStrategy(className)
            this.ClassName = className;
        end
        
        function columnNames = getColumnClassesForImport(this, ~)
            columnNames = this.ClassName;
        end
    end
end