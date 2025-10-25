classdef DataAvailableInfo < handle
    % 'DATAAVAILABLEINFO' is used for passing custom event information from
    % the respective callback handlers to the user specified callback
    % functions.
    
    %   Copyright 2019 The MathWorks, Inc.
    properties
        BytesAvailableFcnCount
        AbsTime
    end
    
    methods
        function data = DataAvailableInfo(count, absolutetime)
            % Save the count and Absolute time
            data.BytesAvailableFcnCount = count;
            data.AbsTime = absolutetime;
        end
    end
end