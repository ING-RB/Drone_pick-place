classdef ResolvedSymbol
    properties (SetAccess=?matlab.lang.internal.introspective.NameResolver)
        classInfo        = [];

        topicInput       = '';
        nameLocation     = '';
        whichTopic       = '';
        resolvedTopic    = '';
        elementKeyword   = '';

        foundVar         = false;

        isCaseSensitive  = true;
        isUnderqualified = false;
        isBuiltin        = false;
        isTypo           = false;
        isAlias          = false;
        isInaccessible   = false;
    end

    properties (Dependent, SetAccess = private)
        isResolved;
    end

    methods
        function location = get.nameLocation(obj)
            if obj.nameLocation == ""
                if ~obj.isResolved
                    obj.nameLocation = matlab.lang.internal.introspective.safeWhich(obj.topicInput, obj.isCaseSensitive);
                else
                    obj.nameLocation = obj.whichTopic;
                end
            end

            location = obj.nameLocation;
        end

        function result = get.isResolved(obj)
            result = obj.isBuiltin || obj.whichTopic ~= "";
        end
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
