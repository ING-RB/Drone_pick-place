classdef Preference
    % Will only emit limited preference changes published by UI callbacks

    methods (Static, Access = public)
        function groupName = groupName()
            groupName = 'simulink_online';
        end % groupName

        %TODO: add keyboard perf name here

        function prefName = autosaveOnClosingName()
            prefName = 'SaveBackupOnlineClosing';
        end % autosaveOnClosingName

        function defaultValue = autosaveOnClosingDefaultValue()
            defaultValue = true;
        end % autosaveOnClosingDefaultValue

        function prefName = clipboardFireFoxWarningName()
            prefName = 'ClipboardFireFoxWarning';
        end % clipboardFireFoxWarningName

        function defaultValue = clipboardFireFoxWarningDefaultValue()
            defaultValue = true;
        end % clipboardFireFoxWarningDefaultValue
    end

    methods (Access = private)
        function obj = Preference()
        end
    end
end
