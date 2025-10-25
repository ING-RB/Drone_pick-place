classdef localConstructor < matlab.lang.internal.introspective.classInformation.constructor
    methods
        function ci = localConstructor(packageName, className, basePath, justChecking)
            definition = fullfile(basePath, append(className, filemarker, className));
            whichTopic = which(fullfile(basePath, className));
            if whichTopic == ""
                whichTopic = basePath;
            end
            ci@matlab.lang.internal.introspective.classInformation.constructor(packageName, className, definition, whichTopic, justChecking);
        end

        function helpText = getSecondaryHelp(ci, justH1)
            % did not find help for the local constructor, see if there is help for the class
            ci.definition = ci.whichTopic;
            ci.minimalPath = ci.definition;
            ci.minimizePath;
            helpText = ci.helpfunc(justH1);
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
