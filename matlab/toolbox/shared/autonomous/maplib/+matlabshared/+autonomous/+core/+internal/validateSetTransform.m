function validateSetTransform(map, fcnHandle)
% This function is for internal use only

%validateSetTransform Verifies that SetTransformFcn is capable of handling the supported syntaxes
%
%   fcn(map, matrix, matrix)
%   fcn(map, scalarVal, location, scalarVal, frame)
%   fcn(map, multiCellValues, locations, multiCellValues, frame)
%   fcn(map, blockValues, botLeft, blockValues, frame)

%   Copyright 2020 The MathWorks, Inc.

%#codegen
    
    % Extract map properties
    dataDims = map.DataSize(3:end);
    val      = map.DefaultValue;
    
    % Generate test inputs
    entireMat        = repmat(val, map.DataSize);
    scalarVal        = val;
    multiCellValues  = repmat(val, [2,1,dataDims]);
    blockValues      = repmat(val, [2,2,dataDims]);
    
    % Call fcnHandle on inputs
    outMatrix = fcnHandle(map, entireMat, entireMat);
    outScalar = fcnHandle(map, scalarVal, [1 1], scalarVal, 'g');
    outVector = fcnHandle(map, multiCellValues, [1 1; 2 2], multiCellValues, 'g');
    outSubMat = fcnHandle(map, blockValues, [1 1], blockValues, 'g');
    
    % Verify that value size is preserved
    coder.internal.assert(isequal(size(outMatrix),size(entireMat)),'shared_autonomous:maplayer:InvalidSetFcn');
    coder.internal.assert(isequal(size(outScalar),size(scalarVal)),'shared_autonomous:maplayer:InvalidSetFcn');
    coder.internal.assert(isequal(size(outVector),size(multiCellValues)),'shared_autonomous:maplayer:InvalidSetFcn');
    coder.internal.assert(isequal(size(outSubMat),size(blockValues)),'shared_autonomous:maplayer:InvalidSetFcn');
end