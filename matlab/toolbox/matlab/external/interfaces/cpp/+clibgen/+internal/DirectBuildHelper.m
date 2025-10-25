classdef DirectBuildHelper < clibgen.internal.BuildHelper

    %  Copyright 2024 The MathWorks, Inc.
    properties(Access=private)
        feOpts
        parsedResults
    end
    methods(Access=private)
        function obj = generateInterfaceCode(obj)
            if isempty(obj.parsedResults.Logger)
                obj.parsedResults.Logger = clibgen.internal.MessageLogger;
            end
            [messageLog, totalCons, numNeedDef] = clibgen.internal.cppbuild(obj.parsedResults,obj.feOpts);
            obj.parsedResults.Logger.HeaderMessages = messageLog;
            obj.parsedResults.Logger.totalConstructs = totalCons;
            obj.parsedResults.Logger.undefinedConstructs = numNeedDef;
            if obj.Verbose && ~isempty(obj.parsedResults.Logger.HeaderMessages)
                if matlab.internal.display.isHot
                    warning(message('MATLAB:CPP:WarningsFromHeader_link', obj.parsedResults.Logger.getHeaderMessages));
                else
                    warning(message('MATLAB:CPP:WarningsFromHeader', obj.parsedResults.Logger.getHeaderMessages));
                end
            end
            % Check for nothing to call condition
            if obj.parsedResults.Logger.totalConstructs == 0
                error(message('MATLAB:CPP:NoConstructsFoundCheckFiles'));
            end
            % Check if no C++ symbols to call because need definition
            numConstructsDefined = obj.parsedResults.Logger.totalConstructs-obj.parsedResults.Logger.undefinedConstructs;
            if numConstructsDefined == 0 && obj.parsedResults.Logger.undefinedConstructs > 0
                error(message('MATLAB:CPP:NoConstructsRunGenerate'));
            end
        end
    end
    methods(Access=public)
        function obj = DirectBuildHelper(parsedResults, feOpts)
            obj@clibgen.internal.BuildHelper(parsedResults.InterfaceName, parsedResults.OutputFolder);
            obj.IncludePath = parsedResults.IncludePath;
            obj.Libraries = parsedResults.Libraries;
            obj.SourceFiles = parsedResults.SupportingSourceFiles;
            obj.DefinedMacros = parsedResults.DefinedMacros;
            obj.UndefinedMacros = parsedResults.UndefinedMacros;
            obj.AdditionalCompilerFlags = parsedResults.AdditionalCompilerFlags;
            obj.AdditionalLinkerFlags = parsedResults.AdditionalLinkerFlags;
            obj.Verbose = parsedResults.Verbose;
            obj.feOpts = feOpts;
            obj.parsedResults = parsedResults;
            obj.BuildMode = 1;
        end
        function build(obj)
            obj.errorIfInterfaceIsInUse;
            obj.createInterfaceDir;
            obj = obj.generateInterfaceCode;
            disp(message('MATLAB:CPP:BuildStarted', obj.InterfaceFile, obj.InterfaceName).getString);
            obj.buildInterfaceCode;
            obj.displaySuccessMessages;
            % Display message to indicate whether to use generateLibraryDefinition
            if(obj.parsedResults.Logger.undefinedConstructs > 0)
                disp(message('MATLAB:CPP:ConsiderGenerateAndBuild', num2str(obj.parsedResults.Logger.undefinedConstructs)).getString);
            end
            if ~obj.Verbose && ~isempty(obj.parsedResults.Logger.HeaderMessages)
                disp(message('MATLAB:CPP:UseVerboseMode').getString);
            end
        end
    end
end