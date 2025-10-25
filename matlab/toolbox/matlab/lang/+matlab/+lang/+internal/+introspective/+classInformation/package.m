classdef package < matlab.lang.internal.introspective.classInformation.base
    properties (SetAccess=private, GetAccess=private)
        isExplicit  (1,1) logical = false;
        packageName (1,1) string  = "";
    end

    methods
        function ci = package(packagePath, isExplicit, isUnique)
            ci@matlab.lang.internal.introspective.classInformation.base(matlab.lang.internal.introspective.getPackageName(packagePath), packagePath, packagePath);
            ci.isExplicit = isExplicit;
            ci.isMinimal = ~isUnique;
            ci.packageName = ci.definition;
            ci.isPackage = true;
        end

        function topic = fullTopic(ci)
            % since the definition has been modified by overqualifyTopic,
            % this needs to be overloaded to keep things nice.
            topic = ci.packageName;
        end

        function helpText = getHelpForDescription(ci)
            ci.whichTopic = matlab.lang.internal.introspective.safeWhich(fullfile(ci.minimalPath, 'Contents.m'));
            ci.definition = ci.whichTopic;
            helpText = ci.helpfunc(false);
        end
    end

    methods (Access=protected)
        function overqualifyTopic(ci, topic)
            % if a package name has been overqualified to distinguish it from
            % another directory, add it back here
            overqualifiedPath = matlab.lang.internal.introspective.splitOverqualification(ci.minimalPath, topic, ci.whichTopic);
            if ci.isExplicit
                ci.definition = append(overqualifiedPath, ci.minimalPath);
            else
                ci.definition = append(overqualifiedPath, regexprep(ci.minimalPath, '[@+]', ''));
            end
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
