function varargout = displayOverloads(topic, shouldHotlink, command)
    arguments
        topic         (1,1) string;
        shouldHotlink (1,1) logical = matlab.internal.display.isHot;
        command       (1,1) string  = "help";
    end

    imports = matlab.lang.internal.introspective.callerImports;
    list = matlab.lang.internal.introspective.overloads.getOverloads(topic, imports, ShouldFormatSeparator=shouldHotlink);
    emptyListID = 'MATLAB:introspective:help:NoOverloadedMethods';

    topic = regexp(topic,'\w+$','match','once');

    [varargout{1:nargout}] = matlab.internal.help.displayOtherNamesList(topic, list, emptyListID, shouldHotlink, command);
end

%   Copyright 2015-2024 The MathWorks, Inc.
