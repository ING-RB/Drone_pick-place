% This method is used when classes modify the global format for the purpose of
% getting disp value in a different format. In this case, if tempFormat existed
% before, we restore to formatToRestore as is. If temp format did not exist,
% then we clear temporaryValue as this could have likely been reset by the
% calling class.

% Copyright 2015-2025 The MathWorks, Inc.

function restoreNumericFormat (formatToRestore, hasTempFormat)
    if hasTempFormat
        format(formatToRestore);
    else
        s = settings;
        if s.matlab.commandwindow.NumericFormat.hasTemporaryValue
            s.matlab.commandwindow.NumericFormat.clearTemporaryValue;
        end
    end
end
