function binaryArray = buildBinary(binaryArray, nullIndices)
%BUILDBINARY
%  Builds a cell array of uint8 row vectors.
%
% BINARYARRAY is a cell array of uint8 vectors.
%
% NULLINDICES is a logical array representing nulls in the binary array.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        binaryArray (:, 1) cell
        nullIndices logical
    end

    binaryArray(nullIndices) = {missing};    
end

