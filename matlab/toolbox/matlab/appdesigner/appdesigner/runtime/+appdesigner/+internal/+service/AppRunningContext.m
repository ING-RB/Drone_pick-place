classdef AppRunningContext < handle
    %APPRUNNINGCONTEXT A singleton instance to hold web app running context data
    %   per MATLAB session
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Access=private)
        ContextInstance
    end
    
    methods(Access=private)
        % Private constructor to prevent creating object externally
        function obj = AppRunningContext()
            obj.ContextInstance = struct.empty();
        end
    end
    
    methods(Static)
        % Get singleton instance of the AppRunningContext
        function obj = instance()
            persistent localUniqueInstance;
            if isempty(localUniqueInstance)
                obj = appdesigner.internal.service.AppRunningContext();
                localUniqueInstance = obj;
            else
                obj = localUniqueInstance;
            end
        end
        
        function set(context)
            obj = appdesigner.internal.service.AppRunningContext.instance();
            obj.ContextInstance = context;
        end
        
        function context = get()
            if (isdeployed && matlab.internal.environment.context.isWebAppServer)
               % Run under webapp, and the context is set from MDWAS
               % In the future, if MDWAS supports multiple sessions per
               % MATLAB instance (CTFLauncher), context could be stored
               % with session id 
               obj = appdesigner.internal.service.AppRunningContext.instance();
               context = obj.ContextInstance;
            else
                rootObj = groot;
                context.viewportSize = [];
                context.devicePixelRatio = [];
                context.orientation = [];
                context.screenSize = rootObj.ScreenSize;
                context.ppi = rootObj.ScreenPixelsPerInch;
            end
        end
    end
end

