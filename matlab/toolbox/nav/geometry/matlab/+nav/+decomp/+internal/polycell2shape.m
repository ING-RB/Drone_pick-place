function polySet = polycell2shape(pCells,vertices)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

% polycell2shape Convert list of polyCells to polyshape array
    
%#codegen

    if coder.target("MATLAB")
        polySet = reshape(arrayfun(@(x)nav.decomp.internal.PolyCell.asPoly(x,vertices),pCells),[],1);
    else
        polySet = nav.decomp.internal.polyshapeMgr;
        for i = 1:numel(pCells)
            polySet = [polySet;nav.decomp.internal.PolyCell.asPoly(pCells(i),vertices)]; %#ok<AGROW>
        end
    end
end
