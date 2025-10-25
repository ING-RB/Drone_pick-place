classdef (Abstract) DataQueueAccess
    %DATAQUEUEACCESS Access class for DataQueue internal methods

    %   Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function redirectDiaryToCaller(dataQueue)
            dataQueue.redirectDiaryToCaller();
        end

        function redirectDiaryToDefault(dataQueue)
            dataQueue.redirectDiaryToDefault();
        end
    end
end