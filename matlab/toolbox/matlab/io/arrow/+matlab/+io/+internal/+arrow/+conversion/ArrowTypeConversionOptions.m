classdef ArrowTypeConversionOptions < matlab.mixin.Scalar
    %ARROWTYPECONVERSIONOPTIONS Controls conversion of Arrow types to MATLAB types.
    
    %   Copyright 2021-2022 The MathWorks, Inc.

    properties
        % LogicalTypeConversionOptions   Controls how logical types are converted.
        LogicalTypeConversionOptions(1, 1) matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions();

        % IntegerTypeConversionOptions   Controls how integer types are converted.
        IntegerTypeConversionOptions(1, 1) matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions();
    end

    properties(Constant, Hidden)
        % save-load metadata
        ClassVersion(1, 1) double = 1;
        EarliestSupportedVersion(1, 1) double = 1;
    end

    methods
        function obj = ArrowTypeConversionOptions(opts)
            arguments
                opts.?matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions
            end
            for field = string(fieldnames(opts))'
                obj.(field) = opts.(field);
            end
        end
    end

    methods(Hidden)
        function s = saveobj(obj)
            s.ClassVersion = obj.ClassVersion;
            s.EarliestSupportedVersion = obj.EarliestSupportedVersion;
            s.LogicalTypeConversionOptions = obj.LogicalTypeConversionOptions;
            s.IntegerTypeConversionOptions = obj.IntegerTypeConversionOptions;
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            import matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions

            % Error if we are sure that a version incompatibility is about to occur.
            if s.EarliestSupportedVersion > ArrowTypeConversionOptions.ClassVersion
                error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
            end

            obj = ArrowTypeConversionOptions();
            obj.LogicalTypeConversionOptions = s.LogicalTypeConversionOptions;
            obj.IntegerTypeConversionOptions = s.IntegerTypeConversionOptions;
        end
    end
end
