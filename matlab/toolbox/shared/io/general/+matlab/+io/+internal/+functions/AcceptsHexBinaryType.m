classdef AcceptsHexBinaryType < matlab.io.internal.FunctionInterface
    % ACCEPTSHEXBINARYTYPE An interface for functions which accept a HEXTYPE & BINARYTYPE.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Parameter) % Properties Supported by text & XML files
        HexType = 'auto';
        BinaryType = 'auto';
    end
    
    properties (Constant)
        TypesHexBin = {'auto','text','int8','int16','int32','int64','uint8','uint16','uint32','uint64'};
    end
    
    methods
        function func = set.HexType(func,rhs)
            func.HexType = validatestring(rhs, func.TypesHexBin);
        end
        
        function func = set.BinaryType(func,rhs)
            func.BinaryType = validatestring(rhs, func.TypesHexBin);
        end
    end
end