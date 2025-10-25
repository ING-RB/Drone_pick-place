classdef ApiBuildHelper < clibgen.internal.BuildHelper

    %  Copyright 2024 The MathWorks, Inc.
    properties(Access=private)
        ast
    end
    methods(Access=private)
        function generateInterfaceCode(obj)
            dataFileName = fullfile(obj.InterfaceDir,obj.InterfaceName) + "Data.xml";
            % generate XML
            internal.cxxfe.ast.Ast.serializeToFile(obj.ast,dataFileName,internal.cxxfe.ast.io.IoFormat.bin);
            % generate interface code
            clibgen.internal.cppdefinebuild(obj.ast,obj.InterfaceDir,obj.InterfaceName);
        end
    end
    methods(Access=public)
        function obj = ApiBuildHelper(idef)
            arguments
                idef clibgen.api.InterfaceDefinition
            end
            obj@clibgen.internal.BuildHelper(idef.InterfaceName, idef.OutputFolder);
            obj.IncludePath = idef.IncludePath;
            obj.Libraries = idef.Libraries;
            obj.SourceFiles = idef.SourceFiles;
            obj.DefinedMacros = idef.DefinedMacros;
            obj.UndefinedMacros = idef.UndefinedMacros;
            obj.AdditionalCompilerFlags = idef.AdditionalCompilerFlags;
            obj.AdditionalLinkerFlags = idef.AdditionalLinkerFlags;
            obj.Verbose = idef.DisplayOutput;
            obj.ast = idef.Ast;
            obj.BuildMode = 3;
        end
        function build(obj)
            obj.errorIfInterfaceIsInUse;
            obj.createInterfaceDir;
            obj.generateInterfaceCode;
            if obj.Verbose
                disp(message('MATLAB:CPP:BuildStarted', obj.InterfaceFile, obj.InterfaceName).getString);
            end
            obj.buildInterfaceCode;
            if obj.Verbose
                obj.displaySuccessMessages;
            end
        end
    end
end