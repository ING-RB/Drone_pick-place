classdef ScaleMethodMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2018-2020 The MathWorks, Inc.

    properties(SetObservable = true)
        ScaleMethod inspector.internal.datatype.ScaleMethod
    end

    methods
        function set.ScaleMethod(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).ScaleMethod, char(inspectorValue))
                    obj.OriginalObjects(idx).ScaleMethod = char(inspectorValue); %#ok<*MCNPR>
                end
            end
        end

        function value = get.ScaleMethod(obj)
            value = inspector.internal.datatype.ScaleMethod.(obj.OriginalObjects(end).ScaleMethod);
        end
    end
end
