classdef BuildHelper

    %  Copyright 2024 The MathWorks, Inc.
    properties(SetAccess=private,GetAccess=protected)
        InterfaceName   string
        OutputFolder    string
        InterfaceDir    string
        InterfaceFile   string
        ExecutionMode   string
    end
    properties(Access=protected)
        IncludePath     string
        Libraries       string
        SourceFiles     string
        DefinedMacros   string
        UndefinedMacros string
        AdditionalCompilerFlags   string
        AdditionalLinkerFlags     string
        Verbose         logical
        BuildMode
    end
    properties(Access=private)
        newInterfaceDir logical
    end 
    methods(Access=protected)
        function obj = BuildHelper(interfaceName, outputFolder)
            obj.InterfaceName = interfaceName;
            obj.OutputFolder = outputFolder;
            obj.InterfaceDir = fullfile(obj.OutputFolder, obj.InterfaceName);
            ext = getExtension;
            obj.InterfaceFile = strcat(obj.InterfaceName,'Interface',ext);
            obj.ExecutionMode = getExecutionMode(obj.InterfaceName);
        end
        function errorIfInterfaceIsInUse(obj)
            % Throw rebuild error if the user is trying to build C++ interface with a
            % interfaceName that has been used in the current MATLAB session
            isloaded = clibgen.internal.clibpackageisLoaded(obj.InterfaceName);
            if isloaded
                if obj.ExecutionMode == "inprocess"
                    switch obj.BuildMode
                        case 1
                            mexp = MException('MATLAB:CPP:RebuildError', message('MATLAB:CPP:RebuildErrorBuildInterface', obj.InterfaceName, obj.InterfaceFile).getString());
                        case 2
                            mexp = MException('MATLAB:CPP:RebuildError', message('MATLAB:CPP:RebuildErrorDefineAndBuild', obj.InterfaceName, obj.InterfaceFile).getString());
                        case 3
                            % Todo: Add a new msg id for api workflow
                            % rebuild error
                            mexp = MException('MATLAB:CPP:RebuildError', message('MATLAB:CPP:RebuildErrorBuildInterface', obj.InterfaceName, obj.InterfaceFile).getString());
                    end
                else
                    mexp = MException('MATLAB:CPP:RebuildError', message('MATLAB:CPP:RebuildErrorOutOfProcess', obj.InterfaceFile, obj.InterfaceName).getString());
                end
                throwAsCaller(mexp)
            end
        end
        function obj = createInterfaceDir(obj)
            try
                if exist(obj.InterfaceDir, 'file') == 2
                    % Error if there is a file with InterfaceName exists in OutputFolder
                    error(message('MATLAB:CPP:FileExistsWithPackageName', obj.InterfaceDir));
                else
                    if exist(obj.InterfaceDir, 'dir') == 0
                        % Create New directory if does not exist
                        obj.newInterfaceDir = true;
                        mkdir(obj.InterfaceDir);
                    else
                        obj.newInterfaceDir = false;
                    end
                end
            catch ME
                throwAsCaller(ME)
            end
        end
        function buildInterfaceCode(obj)
            srcFile = char(fullfile(obj.InterfaceDir, strcat(obj.InterfaceName,'Interface.cpp')));
            if ~isempty(obj.Libraries)
                [status,cmdOut] = clibgen.internal.build(srcFile,cellstr(obj.Libraries),cellstr(obj.SourceFiles),cellstr(obj.IncludePath),obj.InterfaceDir,obj.DefinedMacros,obj.UndefinedMacros, ...
                    join(obj.AdditionalCompilerFlags, " "), join(obj.AdditionalLinkerFlags, " "), obj.Verbose, false);
            else
                [status,cmdOut]  = clibgen.internal.build(srcFile,"",cellstr(obj.SourceFiles),cellstr(obj.IncludePath),obj.InterfaceDir,obj.DefinedMacros,obj.UndefinedMacros, ...
                    join(obj.AdditionalCompilerFlags, " ") , join(obj.AdditionalLinkerFlags, " "), obj.Verbose, false);
            end
            if status ~=0
                if obj.newInterfaceDir
                    % Remove the new interface directory in case of error
                    rmdir(obj.InterfaceDir, 's');
                end
                error(message('MATLAB:CPP:BuildCmdFailure', cmdOut));
            end
        end
        function displaySuccessMessages(obj)
            disp(message('MATLAB:CPP:BuildCmdSuccess', obj.InterfaceFile, obj.InterfaceDir).getString);
            if matlab.internal.display.isHot
                disp(message('MATLAB:CPP:BuildCmdSuccess_link', obj.InterfaceDir).getString);
            end
            if obj.ExecutionMode == "inprocess"
                changeMode = "outofprocess";
            else
                changeMode = "inprocess";
            end
            if matlab.internal.display.isHot
                display(message('MATLAB:CPP:ExecutionModeInfo', obj.InterfaceName, obj.ExecutionMode, ...
                    message('MATLAB:CPP:ExecutionModeChange_Link',obj.InterfaceName,changeMode).getString).getString);
            else
                display(message('MATLAB:CPP:ExecutionModeInfo', obj.InterfaceName, obj.ExecutionMode, ...
                    message('MATLAB:CPP:ExecutionModeChange_WithoutLink',obj.InterfaceName,changeMode).getString).getString);
            end
        end
    end
end
function executionMode = getExecutionMode(interfaceName)
    s = settings;
    interfaceName = char(interfaceName);
    if hasGroup(s.matlab.external.interfaces.cpp, interfaceName)
        executionMode = s.matlab.external.interfaces.cpp.(interfaceName).ExecutionMode.ActiveValue;
    else
        % default executionMode will be 'inprocess' if there are no settings found
        executionMode = "inprocess";
    end
end
function ext = getExtension
    if ispc
        ext = '.dll';
    elseif ismac
        ext = '.dylib';
    else
        ext = '.so';
    end
end