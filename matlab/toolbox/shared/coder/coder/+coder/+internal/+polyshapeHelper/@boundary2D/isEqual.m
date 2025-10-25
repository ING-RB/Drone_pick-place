function b = isEqual(bnd, other)
%

%   Copyright 2022 The MathWorks, Inc.

    %#codegen
        
    if ~isequal(bnd.bType, other.bType)
        b = false;
        return;
    end
    
    for i = 1:numel(bnd.bType)
        if bnd.bType(i) ~= other.bType(i) || bnd.getBoundarySize(i) ~= other.getBoundarySize(i)
            b = false;
            return;
        end
        for j = 1:bnd.getBoundarySize(i)
            
            [x1, y1] = bnd.getCoordAtIdx(i, j);
            [x2, y2] = other.getCoordAtIdx(i, j);
            if (x1 ~= x2 || y1 ~= y2)
                b = false;
                return;
            end
        end
    end
    b = true;
end
