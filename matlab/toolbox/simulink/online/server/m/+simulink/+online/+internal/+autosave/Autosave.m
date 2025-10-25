% Copyright 2021 The MathWorks, Inc.

classdef Autosave < handle
    methods (Static, Access = public)
        function inst = getInstance()
            persistent s_inst;
            import simulink.online.internal.autosave.Autosave;
            if isempty(s_inst)
                s_inst = Autosave();
            end
            inst = s_inst;
        end
    end

    methods (Access = public)

      function start(this)
          if this.m_started
              return;
          end

          if ~this.m_inited
              this.init();
          end

          % assert ~isempty(this.m_autosaveController)
          % TODO: need localization?
          this.m_logger.info('Start Simulink online autosave');
          this.m_autosaveController.start();

          % Connect to preference change
          import simulink.online.internal.events.PreferenceChangeEmitter;
          prefEmitter = PreferenceChangeEmitter.getInstance();
          this.m_hListenerPrefChange = prefEmitter.connect(...
              PreferenceChangeEmitter.EVT_CHANGE_ON_SL_PREF_DIALOG,...
              @(src, evtData) this.onPreferenceChanged()...
          );

          this.m_started = true;
      end  % startModelAutoSave

      function stop(this)
          if ~this.m_started
              return;
          end
          this.m_started = false;

          % assert ~isempty(m_autosaveController)
          % TODO: need localization?
          this.m_logger.info('Stop Simulink online autosave');
          this.m_autosaveController.stop();

          % Disconnect
          delete(this.m_hListenerPrefChange);
          this.m_hListenerPrefChange = [];
      end  % startSessionLoad

      function onPreferenceChanged(this)
          if ~this.m_started
              return;
          end
          this.m_autosaveController.invalidate();
      end  % onPreferenceChanged

      function delete(this)
          this.stop();
      end
    end

    methods (Access = protected)
      function obj = Autosave()
      end

      function init(this)
          this.m_inited = true;

          % Create logger, task, scheduler, control, and connect
          % In the future, if there are more than one progress, and more than one
          % user profile which requires different procedures
          % We can create factories that generate different strategies consist of
          % different chains of tasks
          import simulink.online.internal.autosave.*;
          import simulink.online.internal.log.Logger;
          this.m_logger = Logger('slonline::autosave');
          autosaveTask = DesktopAutosaveTask(this.m_logger);
          sessionEndScheduler = SessionEndTriggeredScheduler(this.m_logger);
          this.m_autosaveController = SingleScheduledTaskController(...
              autosaveTask, this.m_logger...
          );
          this.m_autosaveController.addScheduler('sessionEnd', sessionEndScheduler);
      end  % init
    end

    % % Test APIs
    % methods (Access = protected)
    % end

    properties (Access = protected)
        m_inited = false;
        m_autosaveController = [];
        m_logger = [];
        m_started = false;
        m_hListenerPrefChange = [];
    end
end
