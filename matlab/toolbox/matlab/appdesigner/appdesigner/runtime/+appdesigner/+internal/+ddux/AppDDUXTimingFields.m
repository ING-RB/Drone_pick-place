classdef AppDDUXTimingFields
    %AppDDUXTimingFields Class to store DDUX timing data fields.

%   Copyright 2024 The MathWorks, Inc.

    properties
        CreateComponentsStarted  = ""
        CreateComponentsEnded    = ""
        GenerateInitMCodeStarted = ""
        GenerateInitMCodeEnded   = ""
        ServerEnded              = ""
    end

    methods (Access = ?appdesigner.internal.ddux.AppDDUXTimingManager)
        function dataToLog = addCommonTimingFields(obj, dataToLog)
            dataToLog.createComponentsStarted = num2str(obj.CreateComponentsStarted);
            dataToLog.createComponentsEnded = num2str(obj.CreateComponentsEnded);
            dataToLog.serverEnded = num2str(obj.ServerEnded);
        end

        function dataToLog = addPlainTextTimingFields(obj, dataToLog)
            dataToLog.generateInitMCodeStarted = num2str(obj.GenerateInitMCodeStarted);
            dataToLog.generateInitMCodeEnded = num2str(obj.GenerateInitMCodeEnded);
        end
    end
end
