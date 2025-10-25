classdef MATLABInfo
    %MATLABInfo Given name of a MATLAB type, record important qualities
    % of the type. Data should be agnostic of the target language that the
    % type may be mapped to.
    
    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        ClassName (1,1) string = "" % Name of MATLAB type

        Size (1,:) {mustBeA(Size, ["matlab.internal.metadata.ArrayDimension", "meta.ArrayDimension"])} = meta.ArrayDimension.empty() % TODO - these ArrayDimension APIs are going to be merged, simplify this when that happens
        TrueDimension (1,1) int64 = -2 % Undefined=-2, empty=-1, scalar=0, vector=1, 2-D=2, ... Describes dimensions with length that may be >1 and that are not empty
        SizeClassification (1,1) matlab.engine.internal.codegen.DimType = matlab.engine.internal.codegen.DimType.Unknown % Empty vs Scalar vs Vector vs Higher dimension

        HasType (1,1) logical = false % true if type information is available
        HasSize (1,1) logical = false % true if size information is available
        IsReal  (1,1) logical = false % true if mustBeReal is specified

        % The following properties are only useful if we have type info
        IsExternal (1,1) logical = false    % true if type is not shipped with MATLAB (not in toolbox folder and not built-in)
        IsHandleClass (1,1) logical = false % true if type is a handle class. Is value class otherwise.
        IsEnum (1,1) logical = false        % true if type is an Enumeration class

    end


    methods
        function obj = MATLABInfo(validationInfo)
            % MATLABInfo given the validation info for a function/method
            % arg or class property, collate important language-agnostic
            % information for strong-typed interfaces

            arguments (Input)
                validationInfo {mustBeScalarOrEmpty, mustBeA(validationInfo,["meta.Validation", "matlab.internal.metadata.Validation"])} % class meta package API vs function meta API.
                % TODO - if these 2 validation APIs merge, we can simplify this
                % mustBeScalarOrEmpty supports empty validation object case
            end

            if ~isempty(validationInfo) 

                if ~isempty(validationInfo.Class)
                    obj.HasType = true;
                    c = validationInfo.Class;
                    obj.ClassName = string(c.Name);

                    % Determine if class is an enum
                    obj.IsEnum = ~isempty(c.EnumerationMemberList);

                    % Determine if the class is a handle
                    obj.IsHandleClass = matlab.engine.internal.codegen.util.isHandleClass(c);

                    % Determine if a type is external (not shipped with MATLAB)
                    fileLocation = which(obj.ClassName);
                    toolboxFolder = fullfile(matlabroot, 'toolbox');
                    if ~isempty(fileLocation)
                        obj.IsExternal = ~(string(fileLocation).startsWith("built-in") || string(fileLocation).startsWith(toolboxFolder));
                    end



                end

                if ~isempty(validationInfo.Size)
                    % Determine size qualities
                    obj.HasSize = true;
                    obj.Size = validationInfo.Size;
                    [obj.SizeClassification, obj.TrueDimension] = matlab.engine.internal.codegen.classifyArraySize2(obj.Size);
                end


                if isprop(validationInfo, "Functions")

                    funcNames = [validationInfo.Functions.Name];
                    if ~isempty(funcNames)
                        obj.IsReal = sum(funcNames == "mustBeReal") > 0;
                    end

                elseif isprop(validationInfo, "ValidatorFunctions")

                    for k = 1:length(validationInfo.ValidatorFunctions)
                        fh = validationInfo.ValidatorFunctions{k};
                        s = functions(fh);
                        if(string(s.function) == "mustBeReal")
                            obj.IsReal = true;
                        end
                    end

                end

            end
        end
    end
end

