function [polySet,solnInfo] = polygonDecomposition(poly,options)
%polygonDecomposition Decompose polyshape into non-overlapping polygons covering the original area

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments (Input)
        poly (1,1) polyshape
        options (1,1) boustrophedonOptions = boustrophedonOptions(ReturnConnectivity=false);
    end
    arguments (Output)
        polySet 
        solnInfo (1,1) struct
    end
    
    % Turn off polyshape warnings for decomposition, renable after
    cleanWarn = muteWarnings; %#ok<NASGU>

    % Generate set of decomposed polygons
    [pCells, vertices, holeStatus] = nav.decomp.internal.robustDecomposition(poly);
    polySet = nav.decomp.internal.polycell2shape(pCells,vertices);
    
    % Generate connectivity graph
    if nargout > 1
        solnInfo = struct();
        solnInfo.Vertices = vertices;
        solnInfo.VertexOnHole = holeStatus;
        if options.ReturnConnectivity
            solnInfo.Connectivity = nav.decomp.internal.createRobustGraph(pCells,vertices,options);
        end
    end
end

function cleanWarn = muteWarnings
    % Turn off polyshape warnings for decomposition, renable after
    warnings = {'MATLAB:polyshape:repairedBySimplify'...
                'MATLAB:polyshape:boolOperationFailed'...
                'MATLAB:polyshape:boundary3Points'};
    ws = warning;
    cellfun(@(x)warning('off',x),warnings,UniformOutput=false);
    cleanWarn = onCleanup(@()warning(ws));
end