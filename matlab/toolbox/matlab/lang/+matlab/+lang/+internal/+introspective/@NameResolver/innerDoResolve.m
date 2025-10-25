function innerDoResolve(obj, topic)

    obj.resolveExplicitPath(topic);

    if isempty(obj.resolvedSymbol.classInfo) && ~obj.malformed && ~matlab.lang.internal.introspective.isAbsoluteFile(topic)

        if matlab.lang.internal.introspective.isObjectDirectorySpecified(topic)
            obj.malformed = true;
            return;
        end

        % just a slash and dot separated list of names
        obj.resolveImplicitPath(topic);

        if isempty(obj.resolvedSymbol.classInfo) && obj.resolvedSymbol.whichTopic == ""

            obj.resolveUnaryClass(topic);

            if isempty(obj.resolvedSymbol.classInfo) && ~isempty(regexp(topic, '[\\/]', 'once'))
                % which may have found an object dir
                obj.resolveExplicitPath(obj.resolvedSymbol.whichTopic);
            end
        end
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.

