classdef abstractMethod < matlab.lang.internal.introspective.classInformation.localMethod
    methods
        function ci = abstractMethod(classWrapper, className, basePath, classMFile, derivedPath, derivedClass, methodName, packageName)
            ci@matlab.lang.internal.introspective.classInformation.localMethod(classWrapper, className, basePath, classMFile, derivedPath, derivedClass, methodName, packageName);
            ci.isAbstract = true;
        end
    end

    methods (Access=protected)
        function helpText = helpfunc(ci, justH1)
            helpText = matlab.lang.internal.introspective.callHelpFunction(@ci.getHelpTextFromFile, ci.whichTopic, justH1);
        end
    end

    methods (Access=protected)
        function patterns = helpPatterns(~)
            patterns.section = '^(?<offset>\s*methods\>(.|\.{3}.*\n)*\((.|\.{3}.*\n)*\<Abstract(?!\s*=\s*false)(.|\.{3}.*\n)*\)(.|\.{3}.*\n)*)(?<inside>.*\n)*?^\s*end\>';
            patterns.element = '^(?<preHelp>[ \t]*+%.*+\n)*(?<offset>[ \t]*+((\w+|\[[^\]]*\])\s*=\s*)?)(?<element>\w++)';
        end
    end

    methods (Static, Access=protected)
        function [helpText, prependName] = extractHelpText(helpSection)
            helpText = helpSection.preHelp;
            prependName = false;
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
