function is_help_available = isHelpAvailable(topic, commandOption)
    [topic, ~, ~, found] = matlab.internal.help.helpwin.help4topic(topic, commandOption);

    if ~found
        found = isClassHelpAvailable(topic);
    end

    is_help_available = found;
end

function is_class_help_available = isClassHelpAvailable(topic)
    classInfo = [];

    [~, hasLocalFunction] = matlab.lang.internal.introspective.fixLocalFunctionCase(topic);

    if ~hasLocalFunction
        classInfo = matlab.internal.help.helpwin.classInfo4topic(topic, true);
    end

    is_class_help_available = matlab.internal.help.helpwin.displayClass(classInfo);
end

%   Copyright 2020-2024 The MathWorks, Inc.
