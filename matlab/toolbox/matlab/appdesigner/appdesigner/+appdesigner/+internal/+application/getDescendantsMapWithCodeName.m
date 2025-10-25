function childrenMap = getDescendantsMapWithCodeName(parent)
    % Returns all the children of the object, including the
    % grand children, great grand children, etc.

    % Copyright 2019 The MathWorks, Inc.
    
    childrenMap = struct();
    
    if isvalid(parent)
        childrenList = findall(parent, '-property', 'DesignTimeProperties');    

        for ix = 1:numel(childrenList)
            codeName = childrenList(ix).DesignTimeProperties.CodeName;
            childrenMap.(codeName) = childrenList(ix);
        end
    end
end

