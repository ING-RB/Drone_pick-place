classdef IntegerTypeConversionOptions < matlab.mixin.Scalar
    %INTEGERTYPECONVERSIONOPTIONS Controls conversion of integer types.
    
    %   Copyright 2021-2022 The MathWorks, Inc.

    properties
        % CastToDouble   Whether to cast to double.
        CastToDouble(1, 1) logical = true;

        % NullFillValue   Sentinel value used to fill NULL array slots.
        NullFillValue(1, 1) = NaN;
    end

    properties(Constant, Hidden)
        % save-load metadata
        ClassVersion(1, 1) double = 1;
        EarliestSupportedVersion(1, 1) double = 1;
    end

    methods
        function obj = IntegerTypeConversionOptions(opts)
            arguments
                opts.?matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions
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
            s.CastToDouble = obj.CastToDouble;
            s.NullFillValue = obj.NullFillValue;
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            import  matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions

            % Error if we are sure that a version incompatibility is about to occur.
            if s.EarliestSupportedVersion > IntegerTypeConversionOptions.ClassVersion
                error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
            end

            obj = IntegerTypeConversionOptions;
            obj.CastToDouble = s.CastToDouble;
            obj.NullFillValue = s.NullFillValue;
        end
    end
end

