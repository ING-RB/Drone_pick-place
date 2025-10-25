classdef JavaScriptCallback < handle
%

%   Copyright 2011-2020 The MathWorks, Inc.

    properties
        RealCallback
    end
    
    methods
        function obj = JavaScriptCallback(callback)
            obj.RealCallback = callback;
        end
        
        function execute(obj,~,data)
            c = onCleanup(@() obj.delete);
            obj.RealCallback(char(data.getData));
        end
    end
    
end

