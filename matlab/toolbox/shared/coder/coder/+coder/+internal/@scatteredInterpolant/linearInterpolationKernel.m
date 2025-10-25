function yi = linearInterpolationKernel(interpObj, xi, yi, nFuncVal, ...
                                        nSamplePts, extrapFuncHandle)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(extrapFuncHandle)
if ~allfinite(xi)
    yi(:) = coder.internal.interpolate.interpNaN(interpObj.sampleVal);
else
    doExtrap = true;
    % sxId contains simplex ID if inside a triangle, else -1.
    sxId = interpObj.delTri.tsearch(xi);
    if sxId ~= -1
        % wkspc is matrix 'A' in the equation, xA = B
        % bc is 'B', the query point horzcat with 1.
        % where x,A,B are respectively, this can be generalized to 3D.
        % (l1 l2 l3) * (x1 y1 1)   (xq yq 1)
        %              (x2 y2 1) =
        %              (x3 y3 1)

        spDim = interpObj.delTri.numSpatialDim();

        % vxId contains the IDs of the vertices forming the triangle.
        vxId = interpObj.delTri.getVtxIDsOfSimplex(sxId);

        wkspc = coder.nullcopy(zeros(spDim+1,'double'));
        for i = 1:spDim+1
            wkspc(i,:) = [interpObj.delTri.getVertexAtID(vxId(i)) 1];
        end
        bc = [xi 1];

        % isQryVtx contains the index of the point in 'vxId' if the query point is a vertex else 0
        [isQryVtx, bc] = coder.internal.scatteredInterpolant.solveBarycentricEqs( ...
            wkspc, bc, interpObj.delTri.spatialDim);
        if isQryVtx
            doExtrap = false;
            for j = 0:nFuncVal-1
                yi(j+1) = interpObj.sampleVal(vxId(isQryVtx) + j*nSamplePts);
            end
        else
            doExtrap = ~(allfinite(bc));
            if ~doExtrap
                for j = 0:nFuncVal-1
                    yi(j+1) = 0;
                    for i = 1:spDim+1
                        yi(j+1) = yi(j+1) + ...
                                  bc(i)*interpObj.sampleVal(vxId(i) + j*nSamplePts);
                    end
                end
            end
        end
    end
    if doExtrap
        yi = extrapFuncHandle(xi, yi, nFuncVal, nSamplePts);
    end
end
