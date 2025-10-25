classdef DefineBuildHelper < clibgen.internal.BuildHelper

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
        function obj = DefineBuildHelper(libdef, ast)
            arguments
                libdef clibgen.LibraryDefinition
                ast    internal.cxxfe.ast.Ast
            end
            obj@clibgen.internal.BuildHelper(libdef.InterfaceName, libdef.OutputFolder);
            obj.IncludePath = libdef.IncludePathAbsolute;
            obj.Libraries = libdef.LibrariesAbsolute;
            obj.SourceFiles = libdef.SupportingSourceFilesAbsolute;
            obj.DefinedMacros = libdef.DefinedMacros;
            obj.UndefinedMacros = libdef.UndefinedMacros;
            obj.AdditionalCompilerFlags = libdef.AdditionalCompilerFlags;
            obj.AdditionalLinkerFlags = libdef.AdditionalLinkerFlags;
            obj.Verbose = libdef.Verbose;
            obj.ast = ast;
            obj.BuildMode = 2;
        end
        function build(obj)
            obj.errorIfInterfaceIsInUse;
            obj.createInterfaceDir;
            obj.generateInterfaceCode;
            disp(message('MATLAB:CPP:BuildStarted', obj.InterfaceFile, obj.InterfaceName).getString);
            obj.buildInterfaceCode;
            obj.displaySuccessMessages;
        end
    end
end