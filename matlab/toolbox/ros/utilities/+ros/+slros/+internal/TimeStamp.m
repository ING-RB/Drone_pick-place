classdef TimeStamp < handle
    %This class is for internal use only. It may be removed in the future.

    % TIMESTAMP Singleton to store Simulation start time.
    % Example:
    % tsObj = ros.slros.internal.TimeStamp.getInstance();

    %   Copyright 2024 The MathWorks, Inc.
    
    properties(Access=public)
        startTimeStamp
    end
    
    methods(Static, Access=public)
        function obj = getInstance()
            persistent tspInstance__;

            if isempty(tspInstance__)
                tspInstance__ = ros.slros.internal.TimeStamp();
            end
            obj = tspInstance__;
        end
    end
    methods(Access=private)
        function obj = TimeStamp
        end
    end
end

