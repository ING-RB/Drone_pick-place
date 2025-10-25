% Copyright 2021 The MathWorks, Inc.

classdef SingleScheduledTaskController< handle

    methods (Access = public)
        function obj = SingleScheduledTaskController(taskToSchedule, logger)
            % Scheduler hash
            % assert(~isempty(taskToSchedule))
            % assert(~isempty(logger))
            obj.m_schedulers = struct();
            obj.m_task = taskToSchedule;
            obj.m_logger = logger;
        end

        function key = addScheduler(this, key, scheduler)
            % assert ~isempty(scheduler)
            scheduler.setTask(this.m_task);
            this.m_schedulers.(key) = scheduler;

            if this.m_started
                scheduler.start();
            end
        end  % addScheduler

        function removeScheduler(this, key)
            if ~isfield(this.m_schedulers, key)
                return;
            end
            scheduler = this.m_schedulers.(key);
            this.m_schedulers = rmfield(this.m_schedulers, key);
            scheduler.clearTask();
            scheduler.stop();
        end  % removeScheduler

        function start(this)
            if this.m_started
                return;
            end

            if ~this.m_task.isValid()
                return;
            end

            try
                fn = fieldnames(this.m_schedulers);
                for k=1:numel(fn)
                    scheduler = this.m_schedulers.(fn{k});
                    % assert ~isempty(scheduler) && isa(scheduler,'SingleTaskScheduler')
                    scheduler.start();
                end
            catch ex
                this.m_logger.error(getReport(ex));
            end
            this.m_started = true;
        end  % start

        function stop(this)
            if ~this.m_started
                return;
            end

            try
                fn = fieldnames(this.m_schedulers);
                for k=1:numel(fn)
                    scheduler = this.m_schedulers.(fn{k});
                    % assert ~isempty(scheduler) && isa(scheduler,'SingleTaskScheduler')
                    scheduler.stop();
                end
            catch
                this.m_logger.error(getReport(ex));
            end
            this.m_started = false;
        end  % stop

        function hasStarted = started(this)
            hasStarted = this.m_started;
        end  % started

        function invalidate(this)
            if this.m_task.isValid()
                this.start();
            else
                this.stop();
            end
        end  % invalidate

        function delete(this)
            this.stop();
        end
    end

    % protected methods, accessible by unit tests
    methods (Access = {...
                ?simulink.online.internal.autosave.SingleScheduledTaskController,...
                ?ISlOnlineAutoSaveUnitTest...
            })
    end

    properties (Access = protected)
        m_schedulers = [];
        m_task;
        m_logger;
        m_started = false;
    end
end
