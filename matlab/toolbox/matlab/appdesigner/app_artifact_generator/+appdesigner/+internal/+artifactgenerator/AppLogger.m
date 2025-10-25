classdef AppLogger < handle
    %APPLOGGER Logs useful links to the comand window in MW environment for plain-text files

%    Copyright 2024 The MathWorks, Inc.

    properties (Access = private, Hidden)
        DebugMode = false;
    end

    methods (Access = private)
        function obj = AppLogger ()
        end

        function setDebugModeImpl (obj, val)
            if ~isempty(getenv("MW_INSTALL"))
                obj.DebugMode = val;
            end
        end
    end

    methods (Static)
        function obj = instance ()
            persistent loggerInstance;

            if isempty(loggerInstance)
                loggerInstance = appdesigner.internal.artifactgenerator.AppLogger();
            end

            obj = loggerInstance;
        end

        function logLink (varName, varVal, linkText)
            arguments
                varName string
                varVal string
                linkText string
            end

            import appdesigner.internal.artifactgenerator.AppLogger;

            if AppLogger.isDebug()
                assignin('base', varName, varVal);
                disp(append('<a href="matlab:edit(', varName, ')">', linkText, '</a>'));
            end
        end

        function debugMode = isDebug ()
            instance = appdesigner.internal.artifactgenerator.AppLogger.instance();
            debugMode = instance.DebugMode;
        end

        function setDebugMode (val)
            instance = appdesigner.internal.artifactgenerator.AppLogger.instance();
            instance.setDebugModeImpl(val);
        end
    end
end
