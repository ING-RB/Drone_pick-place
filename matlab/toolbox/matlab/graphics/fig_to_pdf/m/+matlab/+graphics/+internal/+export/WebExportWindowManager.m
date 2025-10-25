classdef WebExportWindowManager < handle
    % WebExportWindow Singleton class manageing a cef window
    %   Create web export window: 
    %       webExportWindow = matlab.graphics.internal.export.WebExportWindow.getInstance;

    % Copyright 2023 The MathWorks, Inc.
    methods(Static)
        function value = getInstance()
            % 0 arguments - gets the instance
            % 1+ arguments - clears the instance and gets new instance
            mlock;
            persistent instance;
                 
            % clear instance
            if(nargin >= 1)
                if(~isempty(instance))
                    delete(instance);
                    instance = [];
                end
            end

            % get instance
            if isempty(instance) || ~isvalid(instance)
                instance = matlab.graphics.internal.export.WebExportWindow();
            end

            value = instance;
        end
    end
    
end
