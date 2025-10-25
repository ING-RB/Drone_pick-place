% Converts an object to a cell array

% Copyright 2015-2023 The MathWorks, Inc.

function objAsCell = obj2cell(objArray, props)
    arguments
        objArray
        props = properties(objArray);
    end
    objAsCell = {};
    if isempty(objArray)
        return;
    end

    numProps = length(props);
    l = numel(objArray);
    objAsCell = cell(l, numProps);
    for objIndex = 1:l
        obj = objArray(objIndex);
        for propIndex = 1:numProps
            propName = props{propIndex};
            % Check to make sure that the array properties are accessible for
            % the individual object
            if isprop(obj, propName)
                try
                    objAsCell{objIndex, propIndex} = obj.(propName);
                catch
                    objAsCell{objIndex, propIndex} = [];
                end
            else
                objAsCell{objIndex, propIndex} = [];
            end
        end
    end
end
