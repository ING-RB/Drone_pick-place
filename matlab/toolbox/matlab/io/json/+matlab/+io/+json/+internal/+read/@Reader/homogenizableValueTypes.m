function bool = homogenizableValueTypes(obj)
%HOMOGENIZABLEVALUETYPES Returns whether the valueTypes at the
% current level of the reader are homogenizable.
% Returns whether the values are compatible to be converted to a homogenous
% valueTypes may not be the same, but can be convered to a primitive MATLAB
% type without losing data.

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    uniqueValueTypes = unique(obj.valueTypes);

    function isLogical = allLogical()
        logicalValueTypes = [1, 2];
        isLogical = isempty(setdiff(uniqueValueTypes, logicalValueTypes));
    end

    function bool = onlyNullandString()
        bool = all(ismember(uniqueValueTypes, [JSONType.Null; JSONType.String]));
    end

    function bool = onlyNullAndFloatingPoint()
    % If valueTypes only includes null and numeric values, check
    % whether there are NaN values
        bool = all(ismember(uniqueValueTypes, [JSONType.Null; JSONType.Number])) ...
               && all(obj.numberTypes == NumericType.Double);
    end

    bool = isscalar(uniqueValueTypes) ...
           || (length(uniqueValueTypes) == 2) ...
           && (allLogical() ...
               || onlyNullandString() ...
               || onlyNullAndFloatingPoint());
end
