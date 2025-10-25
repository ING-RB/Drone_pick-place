classdef (Abstract) RunInstantiator < handle
    %RUNINSTANTIATOR abstract class used to instantiate apps from app
    %designer
    
    % Copyright 2021-2024, MathWorks Inc.
    
    properties (Access = protected)
        AppModel % Reference to the app model this will instantiate
    end
    
    methods
        function obj = RunInstantiator(appModel)
            obj.AppModel = appModel;
        end
    end
    
    methods (Abstract)
        runningApp = run(obj, arguments)
        runningApp = launchApp(filepath, arguments)
    end

    methods (Access = protected)
        function setupCleanup(obj, runningInstance, fullFileName)
            if ~isempty(runningInstance) && isvalid(runningInstance)
                className = class(runningInstance);

                addlistener(runningInstance, 'ObjectBeingDestroyed', @(src, e)cleanup(obj, fullFileName, className));
            end
        end

        function cleanup(~, fullFileName, className)
            clear(className);
        end
    end
end

