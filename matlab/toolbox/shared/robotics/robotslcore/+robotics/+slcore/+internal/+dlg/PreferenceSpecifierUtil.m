classdef PreferenceSpecifierUtil
%This class is for internal use only. It may be removed in the future.

%PREFERENCESPECIFIERUTIL collection of utilities for preference
%specifier dialog

%   Copyright 2019-2022 The MathWorks, Inc.


%%
    methods(Static)
        function launch(specifierName, tag)
        % Convenience function for opening the dialog
            addr  = robotics.slcore.internal.dlg.findAndBringToFront(...
                specifierName, ...
                tag,...
                @(x)~isempty(x));
            if isempty(addr)
                addr = eval(specifierName);
                addr.openDialog();
            end
        end

        function str = convertStrToHostName(str)
        % Attempt to enforce some basic hostname constraints
            str = regexprep(str, '[^0-9a-z-A-Z\.]', ''); % remove non alphanumeric chars
            str = regexprep(str, '\.+', '\.');  % remove sequences of periods
            str = regexprep(str, '(^\.|\.$)', ''); % remove prefixed & suffixed periods
        end

        function [num, isValid] = convertStrToPortNum(str)
        % str2double returns NaN if unable to convert
            num = str2double(str);
            [num, isValid] = robotics.slcore.internal.dlg.PreferenceSpecifierUtil.validatePortNum(num);
        end

        function [num, isValid] = validatePortNum(num)
        % validatePortNum validate port number

            isValid = ~isnan(num);
            if isValid
                num = abs(fix(num));
                num = min(num, 65535);
                num = max(num, 1);
            end
        end
    end
end
