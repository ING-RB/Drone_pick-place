classdef (Hidden) ExternalModeUtil 
    %This class is for internal use only. It may be removed in the future.
    
    %ExternalModeUtil- Utility functions for external mode
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    %#codegen
    
    methods (Static)
        function PreConnectXCP(hObj)
            % PreConnectXCP Pre-connect function for XCP on TCP/IP
            extmodeMexArgs = get_param(hObj, 'ExtModeMexArgs');
            modelName = get(getModel(hObj),'Name');
            extModeArgsArray=strsplit(extmodeMexArgs);
            % By default symbols file name is located in build/test folder
            buildDirStruct = RTW.getBuildDir(modelName);
            buildDir = buildDirStruct.BuildDirectory;
            codegenFolder = buildDirStruct.CodeGenFolder;
            mustBeFolder(buildDir);
            fileName = modelName;
            pkgName = ros.codertarget.internal.ProjectTool.getValidPackageName(modelName);
            if ros.codertarget.internal.isRemoteBuild(hObj)
                d = ros2device();
                filePath = [d.ROS2Workspace,'/build/',pkgName,'/',fileName];
            else
                % Determine the debug file path and name based on the operating system
                if ispc
                    fileName = [modelName,'.pdb'];
                    filePath = fullfile(codegenFolder, 'build', pkgName, fileName);
                elseif ismac
                    % When mac with XCP on TCPIP is used, add the dsymutil command
                    % in order to generate the required artifacts after the build
                    execPath = fullfile(codegenFolder, 'build', pkgName, fileName);
                    cmdToExtractDebugInfo = ['dsymutil ' execPath ' --flat'];
                    [status, cmdOutput] = system(cmdToExtractDebugInfo);
                    if status ~= 0
                        error(message('ros:slros2:codegen:CannotGenerateDwarfSymbols', cmdOutput));
                    end
                    fileName = [modelName,'.dwarf'];
                    filePath = fullfile(codegenFolder, 'build', pkgName, fileName);
                else
                    filePath = fullfile(codegenFolder, 'build', pkgName, fileName);
                end
                d = ros2device('localhost');
                d.ROS2Workspace = fullfile(codegenFolder);
                mustBeFile(filePath);
            end
            % Copy debug file to buildDir
            d.getFile(filePath,fullfile(buildDir));
            % Append the extra parameters to the extmodeMexArgs
            % The format is 0 IP Port modelName.elf
            data = codertarget.data.getData(hObj);
            symbolsFileName = fullfile(buildDir,fileName);
            extmodeMexArgs = sprintf('%s %s %s ''%s'' %s',...
                extModeArgsArray{1}, extModeArgsArray{2},...
                extModeArgsArray{3}, symbolsFileName, data.ExtModeInfo.TargetPollingTime);
            set_param(hObj,'ExtModeMexArgs',extmodeMexArgs);
        end

        function CloseFcn(hCS) %#ok<INUSD>
            %CloseFcn Close function for one click external mode
            %   This function is called under the following conditions:
            %   - The external mode model reached the end of its simulation time
            %   - The user pressed "Stop" during the external mode simulation
            %   - An error occurred during the external mode simulation

            % Enable external mode warnings
            warning('on', 'Simulink:Engine:ExtModeCannotDownloadParamBecauseNoHostToTarget');
            warning('on', 'coder_xcp:host:StructParamDataTypeTuningNotSupported');
        end
        
        function SetupFcn(hCS) %#ok<INUSD>
            %SetupFcn Setup function for one click external mode
            %   This function is called under when the user pressed
            %   "Monitor Tune" button

            % Disable external mode warnings about unsupported bus signals
            warning('off', 'Simulink:Engine:ExtModeCannotDownloadParamBecauseNoHostToTarget');
            warning('off', 'coder_xcp:host:StructParamDataTypeTuningNotSupported');
        end
    end
end

