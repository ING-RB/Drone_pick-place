classdef DataTypeSpecification < handle
    %

    %   Copyright 2023 The MathWorks, Inc.
    properties(GetAccess= public, SetAccess = protected)
        Type
        Dimensions
        IsComplex
    end

    methods
        function obj = DataTypeSpecification(aType,theDimensions,options)
            arguments
                aType {mustBeTextScalar, mustBeNonempty};
                theDimensions {mustBeNumeric, mustBeNonempty};
                options.IsComplex (1, 1) logical  {mustBeNonempty} = false;
            end
            obj.Type = aType;
            obj.Dimensions = theDimensions;
            obj.IsComplex = options.IsComplex;
        end
    end
end
