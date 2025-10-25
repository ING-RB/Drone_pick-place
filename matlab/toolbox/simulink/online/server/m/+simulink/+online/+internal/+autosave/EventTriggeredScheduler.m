% Copyright 2021 The MathWorks, Inc.

classdef EventTriggeredScheduler < simulink.online.internal.autosave.SingleTaskScheduler

    methods (Access = public)
        function obj = EventTriggeredScheduler(logger, eventSource, addListenerCB, removeListenerCB)
            % assert(~isempty(eventSource))
            % assert(~isempty(logger))
            % assert(~isempty(addListenerCB))
            % assert(~isempty(removeListenerCB))
            obj = obj@simulink.online.internal.autosave.SingleTaskScheduler();
            obj.m_logger = logger;
            obj.m_eventSource = eventSource;
            obj.m_addListenerCB = addListenerCB;
            obj.m_removeListenerCB = removeListenerCB;
        end

        function start(this)
            % assert ~isempty(this.m_task)
            if ~isempty(this.m_hListener)
                this.stop();
            end

            import simulink.online.internal.log.Utils;
            this.m_hListener = this.m_addListenerCB(...
                this.m_eventSource,...
                @(src, evt) this.m_task.run()...
            );
        end  % start

        function stop(this)
            if isempty(this.m_hListener)
                return;
            end
            this.m_removeListenerCB(this.m_eventSource, this.m_hListener);
            this.m_hListener = [];
        end  % stop
        % TODO: check if we want to add pause and resume for performance
    end

    methods (Access = private)
    end

    properties (Access = protected)
        m_logger;
        m_eventSource;
        m_addListenerCB;
        m_removeListenerCB;
        m_hListener = [];
    end
end
