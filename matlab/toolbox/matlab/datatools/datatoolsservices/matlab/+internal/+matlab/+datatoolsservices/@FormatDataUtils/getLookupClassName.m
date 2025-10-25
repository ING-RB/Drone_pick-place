% returns the lookup classname by matching with WidgetRegistry entry.

% Copyright 2015-2023 The MathWorks, Inc.

function actualClassName = getLookupClassName(originalClass, sampleSet, actualClassName)
    arguments
        originalClass
        sampleSet
        actualClassName = class(sampleSet);
    end

    widgetRegistry = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
    [~,~,matchedVariableClass] = widgetRegistry.getWidgets(originalClass, actualClassName);

    if ~strcmp(actualClassName, matchedVariableClass)
        val = sampleSet;
        % Treat all objects as 'object'.  This can be removed in the future if
        % there is no need to differentiate between 'default' and 'object'
        if isobject(val)
            actualClassName = 'object';
        else
            % We want to 'default' if a matchedclass did not exist.
            actualClassName = matchedVariableClass;
            if isempty(actualClassName) || strcmp(actualClassName, "")
                actualClassName = 'default';
            end
        end
    end
end
