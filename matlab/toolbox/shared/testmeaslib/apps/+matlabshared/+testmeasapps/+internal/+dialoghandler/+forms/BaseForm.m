classdef (Abstract) BaseForm
    %BASEFORM is the base form class that all shared_dialog form classes
    %need to inherit from.

    %   Copyright 2021 The MathWorks, Inc.

    properties
        Title (1, 1) string
    end

    properties (Abstract, Constant)
        Type (1, 1) string
    end

    methods
        function throwInvalidNarginError(obj)
            throwAsCaller(MException(message("shared_testmeaslib_apps:dialog:InvalidNumInputArguments", ...
                obj.Type)));
        end
    end
end

