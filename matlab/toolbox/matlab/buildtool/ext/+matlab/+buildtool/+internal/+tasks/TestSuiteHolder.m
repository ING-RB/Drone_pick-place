classdef TestSuiteHolder < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.


    properties (Transient)
        TestSuite
    end

    methods
        function holder = TestSuiteHolder()
            holder.TestSuite = [];
        end
    end

end