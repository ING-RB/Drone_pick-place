classdef StructNodeNameProvider < matlab.io.internal.FunctionInterface
% STRUCTNODENAMEPROVIDER An interface for functions that accept a STRUCTNODENAME

% Copyright 2020-2024 The MathWorks, Inc.

    properties (Parameter)
        %StructNodeName
        %    Name of XML Element node underneath which readstruct should
        %    start reading a struct.
        StructNodeName = string(missing);
    end

    methods
        function obj = set.StructNodeName(obj, rhs)
            % Validate that if supplied, StructNodeName is a scalar string
            % or char vector.
            validateattributes(rhs,["string", "char"], "scalartext", ...
                 "readstruct","StructNodeName");

            obj.StructNodeName = string(rhs);
        end
    end
end
