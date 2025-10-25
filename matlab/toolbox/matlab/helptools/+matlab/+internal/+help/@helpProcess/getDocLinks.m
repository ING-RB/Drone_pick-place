function getDocLinks(hp)   
    if hp.fullTopic ~= "" && ~hp.isContents
        if hp.objectSystemName == ""
            [path, name] = hp.getPathItem;
            if path ~= ""
                hp.docLinks = matlab.lang.internal.introspective.docLinks(hp.fullTopic, name, []);
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
