% Copyright 2021 The MathWorks, Inc.

classdef SingleTaskScheduler< handle

    methods (Abstract, Access = public)
        start(obj, actionCB);
        stop(obj);
    end

    methods (Access = public)
        function obj = SingleTaskScheduler()
        end

        function setTask(this, taskToSchedule)
            this.m_task = taskToSchedule;
        end  % setTask

        function clearTask(this)
            this.m_task = [];
        end  % clearTask

        function delete(this)
            this.stop();
        end
    end

    methods (Access = private)
    end

    properties (Access = protected)
        m_task = [];
    end
end
