function validateGetTransform(map, fcnHandle)
% This function is for internal use only

%validateGetTransform Verifies that GetTransformFcn is capable of handling the supported syntaxes
%
%   fcn(map, matrix)
%   fcn(map, singleCellValue, location, frame)
%   fcn(map, multiCellValues, locations, frame)
%   fcn(map, blockValues, botLeft, blockSize, frame)

%   Copyright 2020 The MathWorks, Inc.

%#codegen
    
    % Extract map properties
    dataDims = map.DataSize(3:end);
    val      = map.DefaultValue;
    
    % Generate test inputs
    entireMat        = repmat(val, map.DataSize);
    singleCellValue  = repmat(val, [1,1,dataDims]);
    multiCellValues  = repmat(val, [2,1,dataDims]);
    blockValues      = repmat(val, [2,2,dataDims]);
    
    % Call fcnHandle on inputs
    outMatrix = fcnHandle(map, entireMat);
    outScalar = fcnHandle(map, singleCellValue, [1 1], 'g');
    outVector = fcnHandle(map, multiCellValues, [1 1; 2 2], 'g');
    outSubMat = fcnHandle(map, blockValues, [1 1], [2 2], 'g');
    
    % Verify that value size is preserved
    coder.internal.assert(isequal(size(outMatrix),size(entireMat)),'shared_autonomous:maplayer:InvalidGetFcn');
    coder.internal.assert(isequal(size(outScalar),size(singleCellValue)),'shared_autonomous:maplayer:InvalidGetFcn');
    coder.internal.assert(isequal(size(outVector),size(multiCellValues)),'shared_autonomous:maplayer:InvalidGetFcn');
    coder.internal.assert(isequal(size(outSubMat),size(blockValues)),'shared_autonomous:maplayer:InvalidGetFcn');
end