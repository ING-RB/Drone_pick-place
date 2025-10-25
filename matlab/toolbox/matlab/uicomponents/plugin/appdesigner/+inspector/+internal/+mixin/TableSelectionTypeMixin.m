classdef TableSelectionTypeMixin < handle
    % TABLESELECTIONTYPEMIXIN - mixin class for the SelectionType property of
    % Table

    % Copyright 2021 The MathWorks, Inc.

    properties(SetObservable = true)
        SelectionType inspector.internal.datatype.TableSelectionType
    end

    methods
		function set.SelectionType(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).SelectionType, char(inspectorValue))
                    obj.OriginalObjects(idx).SelectionType = char(inspectorValue);
                end
            end
        end

		function value = get.SelectionType(obj)
            value = inspector.internal.datatype.TableSelectionType.(obj.OriginalObjects.SelectionType);
		end
	end
end