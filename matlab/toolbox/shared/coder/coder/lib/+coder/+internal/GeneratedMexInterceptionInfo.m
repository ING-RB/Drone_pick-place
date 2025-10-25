classdef GeneratedMexInterceptionInfo < handle
    %

    %   Copyright 2025 The MathWorks, Inc.

    % GeneratedMexInterceptionInfo - Creates a Map to track whether the 
    % generated MEX file has been invoked or not.

    properties
        InvokedMexMap;
    end

    methods
        function obj = GeneratedMexInterceptionInfo()
            obj.InvokedMexMap = configureDictionary('char', 'logical'); 
        end
    end
end
