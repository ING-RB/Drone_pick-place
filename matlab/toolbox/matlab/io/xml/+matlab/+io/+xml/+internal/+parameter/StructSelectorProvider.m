classdef StructSelectorProvider < matlab.io.internal.FunctionInterface
% STRUCTSELECTORPROVIDER An interface for functions that accept a STRUCTSELECTOR

% Copyright 2020-2024 The MathWorks, Inc.

    properties (Parameter)
        StructSelector = string(missing);
    end

    methods
        function obj = set.StructSelector(obj, rhs)
            % Validate that if supplied, StructSelector is a scalar string
            % or char vector or scalar cellstr.
            
            if iscellstr(rhs) && (~isscalar(rhs) || isempty(rhs))
                rhs = {{}};
            end
            
            if ~all(iscellstr(rhs)) ... 
                    && ~(isstring(rhs) && isscalar(rhs) && ismissing(rhs)) % Scalar string missing selects the entire file.
                validateattributes(rhs,["string", "char"],"scalartext", ...
                     "readstruct","StructSelector");
            end

            obj.StructSelector = string(rhs);
        end
    end
end
