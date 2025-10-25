classdef CPPTypeConverter
    % Holds data and methods for type conversions between CPP and MATLAB

%   Copyright 2023 The MathWorks, Inc.
    
    properties
        % Hardcoded conversion table
        
        ColumnHeaders = {'Description', 'CppType', 'MATLABType','IsScalar', 'MustBeReal'};
        ConversionCellTable = ...
           {"Real Double Scalar",      "double",                               "double", 1, 1; ...
            "Real Double Vector",      "std::vector<double>",                  "double", 0, 1; ...
            "Complex Double Scalar",   "std::complex<double>",                 "double", 1, 0; ...
            "Complex Double Vector",   "std::vector<std::complex<double>>",    "double", 0, 0; ...
            "Real Single Scalar",      "float",                                "single", 1, 1; ...
            "Real Single Vector",      "std::vector<float>"                    "single", 0, 1; ...
            "Complex Single Scalar",   "std::complex<float>",                  "single", 1, 0; ...
            "Complex Single Vector",   "std::vector<std::complex<float>>",     "single", 0, 0; ...
            "Real uint8 scalar",       "uint8_t",                              "uint8", 1, 1; ...
            "Real uint8 vector",       "std::vector<uint8_t>",                 "uint8", 0, 1; ...
            "Complex uint8 scalar",    "std::complex<uint8_t>",                "uint8", 1, 0; ...
            "Complex uint8 vector",    "std::vector<std::complex<uint8_t>>",   "uint8", 0, 0; ...
            "Real uint16 scalar",      "uint16_t",                             "uint16", 1, 1; ...
            "Real uint16 vector",      "std::vector<uint16_t>",                "uint16", 0, 1; ...
            "Complex uint16 scalar",   "std::complex<uint16_t>",               "uint16", 1, 0; ...
            "Complex uint16 vector",   "std::vector<std::complex<uint16_t>>",  "uint16", 0, 0; ...
            "Real uint32 scalar",      "uint32_t",                             "uint32", 1, 1; ...
            "Real uint32 vector",      "std::vector<uint32_t>",                "uint32", 0, 1; ...
            "Complex uint32 scalar",   "std::complex<uint32_t>",               "uint32", 1, 0; ...
            "Complex uint32 vector",   "std::vector<std::complex<uint32_t>>",  "uint32", 0, 0; ...
            "Real uint64 scalar",      "uint64_t",                             "uint64", 1, 1; ...
            "Real uint64 vector",      "std::vector<uint64_t>",                "uint64", 0, 1; ...
            "Complex uint64 scalar",   "std::complex<uint64_t>",               "uint64", 1, 0; ...
            "Complex uint64 vector",   "std::vector<std::complex<uint64_t>>",  "uint64", 0, 0; ...
            "Real int8 scalar",        "int8_t",                               "int8", 1, 1; ...
            "Real int8 vector",        "std::vector<int8_t>",                  "int8", 0, 1; ...
            "Complex int8 scalar",     "std::complex<int8_t>",                 "int8", 1, 0; ...
            "Complex int8 vector",     "std::vector<std::complex<int8_t>>",    "int8", 0, 0; ...
            "Real int16 scalar",       "int16_t",                              "int16", 1, 1; ...
            "Real int16 vector",       "std::vector<int16_t>",                 "int16", 0, 1; ...
            "Complex int16 scalar",    "std::complex<int16_t>",                "int16", 1, 0; ...
            "Complex int16 vector",    "std::vector<std::complex<int16_t>>",   "int16", 0, 0; ...
            "Real int32 scalar",       "int32_t",                              "int32", 1, 1; ...
            "Real int32 vector",       "std::vector<int32_t>",                 "int32", 0, 1; ...
            "Complex int32 scalar",    "std::complex<int32_t>",                "int32", 1, 0; ...
            "Complex int32 vector",    "std::vector<std::complex<int32_t>>",   "int32", 0, 0; ...
            "Real int64 scalar",       "int64_t",                              "int64", 1, 1; ...
            "Real int64 vector",       "std::vector<int64_t>",                 "int64", 0, 1; ...
            "Complex int64 scalar",    "std::complex<int64_t>",                "int64", 1, 0; ...
            "Complex int64 vector",    "std::vector<std::complex<int64_t>>",   "int64", 0, 0; ...
            "Logical Scalar",          "bool",                                 "logical", 1, -1; ... % -1 is don't care about realness
            "Logical Vector",          "std::vector<bool>",                    "logical", 0, -1; ...
            "Enum Scalar",             "[MyEnumClass]",                        "[MyEnumClass]", 1, -1; ... % Handle definition reference, check naming for conflicts
            "Enum Vector",             "std::vector<[MyEnumClass]>",           "[MyEnumClass]", 0, -1; ...
            "Char Scalar",             "char16_t",                             "char", 1, -1; ...
            "Char Vector",             "std::u16string",                       "char", 0, -1; ...
            "String",                  "std::u16string",                       "string", 1, -1; ...
            "String Vector",           "std::vector<std::u16string>",          "string", 0, -1; ...
            "Scalar dictionary",        "matlab::data::Array",                      "dictionary", 1, -1;...
            "Dictionary array",         "matlab::data::Array",                      "dictionary", 0, -1};
        
        ConversionTable;
        
    end

    methods (Static)
        function ret = isMathWorksRestricted(matlabType)
            % Returns if the class is restricted for wrapper generation.
            % MathWorks-authored code is restricted so we check for
            % "built-in" or if in toolbox folder (struct, cell, datetime,
            % clib, dot net obj, etc).

            arguments
                matlabType (1,1) string % fully-qualified class name
            end
            fileLocation = which(matlabType);
            ret = false;
            toolboxFolder = fullfile(matlabroot, 'toolbox');
            if ~isempty(fileLocation)
                fileLocation = string(fileLocation);
                ret = fileLocation.contains("built-in") || ...  % if built-in, the output of "which" should contain "built-in"
                    fileLocation.startsWith(toolboxFolder) || ... % other MathWorks authored code should be in the toolbox folder
                    fileLocation.contains("Java method"); % restrict java objects, special case
            end
        end
    end
    
    methods
        
        function obj = CPPTypeConverter()
            % Create the matlab table for the conversions
            obj.ConversionTable = cell2table(obj.ConversionCellTable, 'VariableNames', obj.ColumnHeaders);
        end

        function [cppType, matched] = convertArg(obj, arg)
            arguments (Input)
                obj (1,1) matlab.engine.internal.codegen.cpp.CPPTypeConverter
                arg (1,1) matlab.engine.internal.codegen.ArgumentTpl
            end

            arguments (Output)
                cppType (1,1) string  % The mapped CPP Type
                matched (1,1) logical % true if the MATLAB type mapped to a specific supported C++ native type on the table
            end
            matlabType = arg.MATLABArrayInfo.ClassName;
            dimension = arg.MATLABArrayInfo.SizeClassification;
            isReal = arg.MATLABArrayInfo.IsReal;
            [cppType, matched] = obj.convertType2CPP(matlabType, dimension, isReal);
        end

        function [cppType, matched] = convertType2CPP(obj, matlabType, dimension, isReal)
            %CONVERTTYPE2CPP Converts a MATLAB type in the table to its CPP type
            %  Given a row of table data, converts the type in MATLAB to its
            %  corresponding CPP type.

            arguments (Input)
                obj (1, 1) matlab.engine.internal.codegen.cpp.CPPTypeConverter
                matlabType (1, 1) string
                dimension (1, 1) matlab.engine.internal.codegen.DimType
                isReal (1, 1) uint64 {mustBeLessThanOrEqual(isReal,1)} % 1 for real numerics, 0 for complex numerics. Non-numerics don't care
            end

            arguments (Output)
                cppType (1,1) string  % The mapped C++ type
                matched (1,1) logical % true if the MATLAB type mapped to a specific supported C++ native type on the table
            end

            import matlab.engine.internal.codegen.*
            cppType = "";
            matched = false; % assert no match initially
            isScalar = (dimension == DimType.Scalar);
            isVector = (dimension == DimType.Vector);
            isMultiDim = (dimension == DimType.MultiDim);

            % Conversion logic
            if(isScalar || isVector)

                % Read translation table and find matches
                matchName = string(obj.ConversionTable.MATLABType).matches(matlabType);
                matchSize = obj.ConversionTable.IsScalar == isScalar;
                matchReal = (obj.ConversionTable.MustBeReal == isReal) | (obj.ConversionTable.MustBeReal == -1);
                matchType = matchName & matchSize & matchReal;

                matches = sum(matchType);
                if(matches == 1)
                    i = find(matchType);
                    cppType = string(obj.ConversionTable.CppType(i));
                    matched = true; % match found

                elseif(matches == 0)
                    % If there is no match for the type use MDA
                    cppType = "matlab::data::Array";

                elseif(matches > 1)
                    % Logic error, we found more than 1 matching CPP type
                    messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                    error(messageObj);
                end

            elseif(isMultiDim)
                % Use MDA if multi-dim
                cppType = "matlab::data::Array";
            else
                cppType = ""; % blank means type is undetermined
            end

        end
        
    end
    
end
