% Copyright 2021 The MathWorks, Inc.

classdef DesktopAutosaveTask < simulink.online.internal.autosave.IScheduledTask

    methods (Access = public)
        function obj = DesktopAutosaveTask(logger)
            % assert(~isempty(logger))
            obj.m_logger = logger;
        end

        function run(this)
            if ~this.isValid()
                return;
            end

            % TODO: need localization?
            this.m_logger.info('slonline: triggered Simulink autosave');

            % Turn on slonline autosave signal and turn on online mode
            % In that mode, we will allow autosave for folders start with /MATLAB *
            % especially for online home folder: /MATLAB Drive
            % For system folder, which is mandatorily readonly,
            % we want the autosave system to throw errors
            % We will catch them and log these errors here
            oldValue = slonline.util.setAutoSave(true);
            Simulink.internal.autosave;
            slonline.util.setAutoSave(oldValue);

            % TODO: need localization?
            this.m_logger.info('slonline: Simulink autosave completed');
        end  % run

        function valid = isValid(this)
            import simulink.online.internal.Preference;
            groupName = Preference.groupName();
            prefName = Preference.autosaveOnClosingName();
            if ispref(groupName, prefName)
                valid = getpref(groupName, prefName);
            else
                valid = Preference.autosaveOnClosingDefaultValue();
            end
        end  % isValid
    end

    methods (Access = private)
    end

    properties (Access = protected)
        m_logger;
    end
end
