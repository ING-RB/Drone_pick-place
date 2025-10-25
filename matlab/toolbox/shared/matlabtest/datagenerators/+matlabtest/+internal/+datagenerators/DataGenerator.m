classdef (HandleCompatible) DataGenerator < matlab.mixin.Heterogeneous
    % DataGenerator - Fundamental interface for all data generators
    %
    %   The DataGenerator interface is the means by which to 
    %   generate data in a particular manner which supports a particular
    %   datatype specification.
    %
    %   Classes which derive from DataGenerator will generate values for
    %   particular datatype specifications from the user.
    %
    %   DataGenerator methods:
    %       generateValues - Generates data values given a DataTypeSpecification
    %       isSupportedBy  - Determines whether or not a concrete DataGenerator
    %                        supports a given type defined through a DataTypeSpecification

    % Copyright 2023 The MathWorks, Inc.
    methods (Abstract)
        returnBoolean = isSupportedBy(obj,aDataTypeSpecification)
        dataValues = generateValues(obj,aDataTypeSpecification)
    end
end