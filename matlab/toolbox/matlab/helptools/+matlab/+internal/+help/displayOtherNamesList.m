function output = displayOtherNamesList(topic, list, emptyListID, shouldHotlink, command)
    arguments
        topic         (1,1) string;
        list          (1,:) string;
        emptyListID   (1,1) string;
        shouldHotlink (1,1) logical = matlab.internal.display.isHot;
        command       (1,1) string  = "help";
    end

    if ~isempty(list)
        text = matlab.lang.internal.introspective.overloads.formatOverloads(list);
        if shouldHotlink
            text = regexprep(text,'(\S*)',append('${matlab.internal.help.createMatlabLink(''', command, ''',$0,$0)}'));
        end
    else
        text = append('    ', getString(message(emptyListID, topic)));
    end

    if nargout > 0
        output = text;
    else
        disp(text);
    end
end

%   Copyright 2020-2024 The MathWorks, Inc.
