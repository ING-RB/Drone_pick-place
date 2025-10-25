classdef FunctionTpl < matlab.engine.internal.codegen.CodeGenSection
    %FunctionTpl Holds function data

%   Copyright 2021 The MathWorks, Inc.
    
    properties
        SectionName = "";
        FullName = "";  % Full name of the function with any namespace prefix in dot notation, if applicable
        ShortName = ""; % Name of the function without any prefix
        SectionContent = "";
        SectionMetaData;
        IndentLevel = 0;
        IsVarargin;
        IsAccessible = true; % Functions on the path are always accessible
        IsImplicit = 0;  % Implicty generated as part of package? Or explicitly specified by user?
        DefiningClass = "";
        IsConstructor = false;
        TemplateSpecSection = "";
        
        InputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl = matlab.engine.internal.codegen.ArgumentTpl.empty() % holds input args (ArgumentTpl)
        
        NumArgsWithMetaData     (1,1) int64 = 0; % holds number of arg with meta structs
        NumArgIn      (1,1) int64 = 0; % holds nargin of the function
        NumOutputs   (1,1) int64 = 0;

        % Holds info regarding output arguments
        MetaFunc; % main metadata object
        NumArgOut  (1,1) uint64 = 0;
        OutputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl = matlab.engine.internal.codegen.ArgumentTpl.empty() % holds output args (ArgumentTpl)
        IsVarargout;
        VacantMeta; % holds where meta-data could be more complete
    end

    properties (Access = private)
        ReportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
    end
    
    methods
        %TODO remove isCSharp upon flag being no longer needed
        function obj = FunctionTpl(functionName, indentLevel, isImplicit, reportObj , isCSharp)
            arguments
               functionName (1,1) string % Function name on path. If package prefix is needed, it should be in dot notation.
               indentLevel  (1,1) int64
               isImplicit   (1,1) logical
               reportObj    (1,1) matlab.engine.internal.codegen.reporting.ReportData
               isCSharp     (1,1) logical = false
            end
            
            obj.IndentLevel = indentLevel;
            obj.SectionMetaData = functionName;
            obj.IsImplicit = isImplicit;
            obj.ReportObj = reportObj;
            %TODO remove isCSharp upon flag being no longer needed
            obj = read(obj, isCSharp);
            
        end
        
        %TODO remove isCSharp upon flag being no longer needed
        function obj = read(obj, isCSharp)
            arguments(Input)
                obj
                isCSharp (1,1) logical = false
            end
            import matlab.engine.internal.codegen.*
            import matlab.engine.internal.codegen.reporting.*
            
            % Read in the metadata
            obj.SectionName = obj.SectionMetaData;
            obj.FullName = string(obj.SectionName);
            nsParts = split(obj.FullName, '.');
            obj.ShortName = nsParts(end);
            
            % Error if function is a built-in (not supported)
            fullFileName = string(which(obj.SectionName));

            if(fullFileName.contains("built-in"))
                messageObj = message("MATLAB:engine_codegen:BuiltinFunctionNotSupported", obj.SectionName);
                error(messageObj);
            end

            % Error if the function's defining file cannot be found for some reason
            [~, correctCaseName, ~] = fileparts(fullFileName); % account for "which()" not having case sensitive input g2684488
            fname = string(split(obj.SectionName, '.'));
            fname = fname(end); % compare case only for function name, not package prefix
            if(~isfile(fullFileName) || ~strcmp(correctCaseName, fname))
                messageObj = message("MATLAB:engine_codegen:FunctionDefinitionNotFound", obj.SectionName);
                error(messageObj);
            end

            % Get metadata using metafunction API
            obj.MetaFunc = matlab.internal.metafunction(obj.FullName);
            % Error if a customer passes a Class as a function
            if isa(obj.MetaFunc,"matlab.internal.metadata.Method")
                messageObj = message("MATLAB:engine_codegen:ClassInputAsFunction", obj.SectionName);
            end
            rawInputArgs = obj.MetaFunc.Signature.Inputs;
            obj.NumArgIn = length(rawInputArgs);
            
            % Collate the input arguments
            for i = 1 : length(obj.MetaFunc.Signature.Inputs)
                obj.InputArgs = [obj.InputArgs matlab.engine.internal.codegen.ArgumentTpl(obj.MetaFunc.Signature.Inputs(i), "input")];
            end
            rawOutputArgs = obj.MetaFunc.Signature.Outputs;
            obj.NumArgOut = length(rawOutputArgs);

            % Record vacant input metadata for reporting
            obj.VacantMeta = [];

            % Note if a method arg is missing type or size metadata
            for i = 1:obj.NumArgIn
                arg = obj.InputArgs(i);
                hasType = arg.MATLABArrayInfo.HasType;
                hasSize = arg.MATLABArrayInfo.HasSize;

                if(~hasType || ~hasSize) % if no type or size, add to vacant metadata
                    mu = matlab.engine.internal.codegen.reporting.MetaUnit("FunctionInputArgument", obj.ShortName, arg.Name, hasSize, hasType);
                    obj.VacantMeta = [obj.VacantMeta mu];
                end
            end
            

            % Collate the output arg data
            obj.OutputArgs = matlab.engine.internal.codegen.ArgumentTpl.empty();
            for i = 1 : obj.NumArgOut
                obj.OutputArgs = [obj.OutputArgs matlab.engine.internal.codegen.ArgumentTpl(rawOutputArgs(i), "output")];
            end

            % Check if varargin or varargout
            obj.IsVarargin = false;
            obj.IsVarargout = false;
            for inputArg = obj.InputArgs
                if inputArg.Kind == matlab.internal.metadata.ArgumentKind.repeating
                    obj.IsVarargin = true;
                end
            end
            for outputArg = obj.OutputArgs
                if outputArg.Kind == matlab.internal.metadata.ArgumentKind.repeating
                    obj.IsVarargout = true;
                end
            end

            % Determine output version for meta-data recording logic
            if string(getenv('OutputTypeSupport'))=="true"
                OutputsVersion = 2;
            else
                OutputsVersion = 2;
            end

            % Record missing output argument metadata if applicable
            if(obj.NumArgOut>0 && OutputsVersion == 2)
                for i = 1 : obj.NumArgOut
                    funcName = obj.SectionName;
                    argName = obj.OutputArgs(i).Name;
                    hasSize = obj.OutputArgs(i).MATLABArrayInfo.HasSize;
                    hasType = obj.OutputArgs(i).MATLABArrayInfo.HasType;
                    if(~hasType || ~hasSize) % if no type or size, add to vacant metadata
                        mu = matlab.engine.internal.codegen.reporting.MetaUnit("FunctionOutputArgument", funcName, argName, hasSize, hasType);
                        obj.VacantMeta = [obj.VacantMeta mu];
                    end
                end
            end


        end
    end
end
