classdef CSharpTypeConverter
    % Holds data and methods for type conversions between CSharp  and MATLAB

%   Copyright 2023 The MathWorks, Inc.
    
    properties
        % Hardcoded conversion table
        % 0 means must be complex
        % 1 means must be real
        ColumnHeaders = {'Description', 'CSharpType', 'MATLABType','IsScalar', 'MustBeReal'};
        ConversionCellTable = ...
           {"Real Double Scalar",      "double",                               "double", 1, 1; ...
            "Real Double Vector",      "double [[CommaToken]]",                  "double", 0, 1; ...
            "complex Double Scalar",   "System.Numerics.Complex",                 "double", 1, 0; ...
            "complex Double Vector",   "System.Numerics.Complex [[CommaToken]]",    "double", 0, 0; ...
            "Single Scalar",      "Single",                                "single", 1, 1; ...
            "Single Vector",      "Single [[CommaToken]]"                    "single", 0, 1; ...
            "complex Single Scalar",    "dynamic",                     "single",1,0;...
            "Complex Single vector",    "dynamic",                     "single",0,0;...
            "uint8 scalar",       "byte",                              "uint8", 1, 1; ...
            "uint8 vector",       "byte [[CommaToken]]",                 "uint8", 0, 1; ...
            "complex uint8 scalar",       "dynamic",                              "uint8", 1, 0; ...
            "complex uint8 vector",       "dynamic",                 "uint8", 0, 0; ...
            "uint16 scalar",      "UInt16",                             "uint16", 1, 1; ...
            "uint16 vector",      "UInt16 [[CommaToken]]",                "uint16", 0, 1; ...
            "complex uint16 scalar",      "dynamic",                             "uint16", 1, 0; ...
            "complex uint16 vector",      "dynamic",                "uint16", 0, 0; ...
            "uint32 scalar",      "uint",                             "uint32", 1, 1; ...
            "uint32 vector",      "uint [[CommaToken]]",                "uint32", 0, 1; ...
            "complex uint32 scalar",      "dynamic",                             "uint32", 1, 0; ...
            "complex uint32 vector",      "dynamic",                "uint32", 0, 0; ...
            "uint64 scalar",      "UInt64",                             "uint64", 1, 1; ...
            "uint64 vector",      "UInt64 [[CommaToken]]",                "uint64", 0, 1; ...
            "complex uint64 scalar",      "dynamic",                             "uint64", 1, 0; ...
            "complex uint64 vector",      "dynamic",                "uint64", 0, 0; ...
            "int8 scalar",        "sbyte",                               "int8", 1, 1; ...
            "int8 vector",        "sbyte [[CommaToken]]",                  "int8", 0, 1; ...
            "complex int8 scalar",        "dynamic",                               "int8", 1, 0; ...
            "complex int8 vector",        "dynamic",                  "int8", 0, 0; ...
            "int16 scalar",       "Int16",                              "int16", 1, 1; ...
            "int16 vector",       "Int16 [[CommaToken]]",                 "int16", 0, 1; ...
            "complex int16 scalar",       "dynamic",                              "int16", 1, 0; ...
            "complex int16 vector",       "dynamic",                 "int16", 0, 0; ...
            "int32 scalar",       "int",                              "int32", 1, 1; ...
            "int32 vector",       "int [[CommaToken]]",                 "int32", 0, 1; ...
            "complex int32 scalar",       "dynamic",                              "int32", 1, 0; ...
            "complex int32 vector",       "dynamic",                 "int32", 0, 0; ...
            "int64 scalar",       "Int64",                              "int64", 1, 1; ...
            "int64 vector",       "Int64 [[CommaToken]]",                 "int64", 0, 1; ...
            "complex int64 scalar",       "dynamic",                              "int64", 1, 0; ...
            "complex int64 vector",       "dynamic",                 "int64", 0, 0; ...
            "Logical Scalar",          "bool",                                 "logical", 1, -1; ... % -1 is don't care about realness
            "Logical Vector",          "bool[[CommaToken]]",                    "logical", 0, -1; ...
            "Enum Scalar",             "[MyEnumClass]",                        "[MyEnumClass]", 1, -1; ... % Handle definition reference, check naming for conflicts
            "Enum Vector",             "[MyEnumClass] [[CommaToken]]",           "[MyEnumClass]", 0, -1; ...
            "Char Scalar",             "char",                             "char", 1, -1; ...
            "Char Vector",             "char [[CommaToken]]",                       "char", 0, -1; ...
            "String",                  "string",                       "string", 1, -1; ...
            "String Vector",           "string [[CommaToken]]",          "string", 0, -1; ...
            "struct",                  "MATLABStruct",                  "struct", 1, -1; ...
            "struct Vector",           "MATLABStruct[[CommaToken]]",    "struct", 0, -1;...
            "Scalar dictionary",        "dynamic",                      "dictionary", 1, -1;...
            "Dictionary array",         "dynamic",                      "dictionary", 0, -1};
        
        ConversionTable;

        OuterCSharpNamespace string
        
    end
    
    methods
        
        function obj = CSharpTypeConverter(OuterCSharpNamespace)
            % Create the matlab table for the conversions
            obj.OuterCSharpNamespace = OuterCSharpNamespace;
            obj.ConversionTable = cell2table(obj.ConversionCellTable, 'VariableNames', obj.ColumnHeaders);
        end

        function [csharpType, matched] = convertArg(obj, arg)
            arguments (Input)
                obj (1, 1) matlab.engine.internal.codegen.csharp.CSharpTypeConverter
                arg (1,1) matlab.engine.internal.codegen.ArgumentTpl
            end

            arguments (Output)
                csharpType (1,1) string  % The mapped .NET Type
                matched (1,1) logical % true if the MATLAB type mapped to a specific supported C++ native type on the table
            end
            matlabType = arg.MATLABArrayInfo.ClassName;
            dimension = arg.MATLABArrayInfo.SizeClassification;
            isReal = arg.MATLABArrayInfo.IsReal;
            [csharpType, matched] = obj.convertType2CSharp(matlabType, dimension, isReal, arg.MATLABArrayInfo);
        end
        
        function [csharpType, matched] = convertType2CSharp(obj, matlabType, dimension, isReal, arrayInfo, dims)
            %CONVERTTYPE2CSharp Converts a MATLAB type in the table to its CSharp type
            %  Given a row of table data, converts the type in MATLAB to its
            %  corresponding C#type.
            
            arguments (Input)
                obj (1, 1) matlab.engine.internal.codegen.csharp.CSharpTypeConverter
                matlabType (1, 1) string
                dimension (1, 1) matlab.engine.internal.codegen.DimType
                isReal (1, 1) uint64 {mustBeLessThanOrEqual(isReal,1)} % 1 for real numerics, 0 for complex numerics. Non-numerics don't care
                arrayInfo matlab.engine.internal.codegen.util.MATLABInfo {mustBeScalarOrEmpty} = matlab.engine.internal.codegen.util.MATLABInfo.empty() % Holds type/size data and analysis
                dims = [];
            end

            arguments (Output)
                csharpType (1,1) string  % The mapped C# type
                matched (1,1) logical % true if the MATLAB type mapped to a specific supported C# native type on the table
            end
            
            import matlab.engine.internal.codegen.*
            csharpType = "";
            matched = false; % assert no match initially
            isScalar = (dimension == DimType.Scalar);
            isVector = (dimension == DimType.Vector);
            isMultiDim = (dimension == DimType.MultiDim);
            
            % Conversion logic
            if(isScalar || isVector || isMultiDim)
                % do the regular conversion
                if(matlabType == 'enum')
                    messageObj = message("MATLAB:engine_codegen:EnumsNotSupported");
                    error(messageObj);
                end
                
                % Read translation table and find matches
                matchName = string(obj.ConversionTable.MATLABType).matches(matlabType);
                matchSize = obj.ConversionTable.IsScalar == isScalar;
                matchReal = (obj.ConversionTable.MustBeReal == isReal) | (obj.ConversionTable.MustBeReal == -1);
                matchType = matchName & matchSize & matchReal;
                
                matches = sum(matchType);
                if(matches == 1)
                    i = find(matchType);
                    csharpType = string(obj.ConversionTable.CSharpType(i));
                    matched = true; % match found
                    if (isVector || isMultiDim)
                        commas = "";
                        if (~isempty(arrayInfo))
                            %arg case
                            for j=1:(arrayInfo.TrueDimension-1)
                                commas = commas + ",";
                            end
                        else
                            %property case
                            if isMultiDim
                                for j=1:(length(dims)-1)
                                    commas = commas + ",";
                                end
                            %vector case can be ignored as there should be
                            %no commas for a vector
                            end
                        end
                        csharpType = replace(csharpType,"[CommaToken]",commas);
                    end
                elseif(matches == 0)
                    if matlabType == "cell"
                        if isScalar
                            csharpType = "object []";
                        else
                            csharpType = "object [[CommaToken]]";
                            commas = "";
                            if (~isempty(arrayInfo))
                                %arg case
                                for j=1:(arrayInfo.TrueDimension-1)
                                    commas = commas + ",";
                                end
                            else
                                %property case
                                if isMultiDim
                                    for j=1:(length(dims)-1)
                                        commas = commas + ",";
                                    end
                                    %vector case can be ignored as there should be
                                    %no commas for a vector
                                end
                            end
                            csharpType = replace(csharpType,"[CommaToken]",commas);
                        end
						% assume to be generated type
                    elseif matlab.lang.internal.introspective.isClass(matlabType)
                        if (obj.OuterCSharpNamespace ~= "")
                            csharpType = obj.OuterCSharpNamespace + "." + matlabType;
                        end
                        csharpType = matlabType;
                        if (isVector || isMultiDim )
                            csharpType = csharpType + "[[CommaToken]]";
                            commas = "";
                            if (~isempty(arrayInfo))
                                %arg case
                                for j=1:(arrayInfo.TrueDimension-1)
                                    commas = commas + ",";
                                end
                            else
                            %property case
                                if isMultiDim
                                    for j=1:(length(dims)-1)
                                        commas = commas + ",";
                                    end
                                    %vector case can be ignored as there should be
                                    %no commas for a vector
                                end
                            end
                            csharpType = replace(csharpType,"[CommaToken]",commas);
                        end
                    else
                        % if there is no match use dynamic
                        csharpType = "dynamic";
                    end
                    
               
                elseif(matches > 1)
                    % Logic error, we found more than 1 matching CSharp type
                    messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                    error(messageObj);
                end
            
            else
                csharpType = "dynamic"; % blank means type is undetermined
            end
            
        end
        
    end
    
end
