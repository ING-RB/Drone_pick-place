classdef ColconBuilder < ros.internal.ROSProjectBuilder
    % This class is for internal use only. It may be removed in the future.

    % ColconBuilder is a wrapper around colcon. Used by ProjectTool to
    % build ROS modules

    % Copyright 2019-2024 The MathWorks, Inc.

    properties (Constant, Hidden)
        CMAKEMINVERSION = '3.15.5'
        FUNCTIONNAME = 'ColconBuilder';
        CMAKETEMPLATE = fullfile(fileparts(mfilename('fullpath')),'CMakeList.txt.tmpl')
        PKGXMLTEMPLATE = fullfile(fileparts(mfilename('fullpath')),'package.xml.tmpl')
        VISIBILITYHTEMPLATE = fullfile(fileparts(mfilename('fullpath')),'visibility_control.h.tmpl')
        CUSTOMMSG_FOLDER_SUFFIX = 'msg/';
        CUSTOMSRV_FOLDER_SUFFIX = 'srv/';
        CUSTOMACTION_FOLDER_SUFFIX = 'action/';
    end

    properties (SetAccess=private,GetAccess=public)
        AmentPrefixPath
    end

    methods
        function h = ColconBuilder(varargin)
            h@ros.internal.ROSProjectBuilder(varargin{:});
            h.AmentPrefixPath = ['"' ros.ros2.internal.getAmentPrefixPath '"'];
        end
    end

    methods (Access=protected)
        function [status, result] = runBuildSystemCommand(h, varargin)
            cmdline = sprintf('%s ',varargin{:});

            if h.UseNinja
                if contains(cmdline,'--cmake-args')
                    cmdline = [cmdline ' -G Ninja '];
                else
                    cmdline = [cmdline ' --cmake-args -G Ninja '];
                end

                % Use Ninja build tool that ships with MATLAB to generate messages
                ninjaBuildTool = fullfile(matlabroot, 'toolbox', 'shared', 'coder', 'ninja', computer('arch'));
                originalPathEnv = getenv('PATH');
                resetPath = onCleanup(@()setenv('PATH',originalPathEnv));
                setenv('PATH',[ninjaBuildTool, pathsep, originalPathEnv]);
            end

            if strcmpi(computer('arch'),'maca64')
                cmdline = [cmdline, ' -DCMAKE_OSX_ARCHITECTURES=arm64 '];
            end

            if strcmpi(computer('arch'),'glnxa64')
                cmdline = [cmdline,' -DCMAKE_C_COMPILER=',h.GccLocation,' -DCMAKE_CXX_COMPILER=',h.GppLocation,' '];
            end

            cmdmap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                {['"' fullfile(fileparts(mfilename('fullpath')),'runcolconcmd') '"  "' strtrim(h.MexInfo.Details.CommandLineShell) '"'], ...use .bat file
                ['"' fullfile(fileparts(mfilename('fullpath')),'runcolconcmd.sh') '"'],... use .sh
                ['"' fullfile(fileparts(mfilename('fullpath')),'runcolconcmd.sh') '"'],... use .sh
                ['"' fullfile(fileparts(mfilename('fullpath')),'runcolconcmd.sh') '"']});
            cmd = cmdmap(computer('arch'));

            cmakeDir = ['"' fullfile(matlabroot,'bin',computer('arch'),'cmake','bin') '"'];
            [status, result] = system([cmd, ' ', h.AmentPrefixPath, ' ', h.PyEnvDir, ' ', cmakeDir, ' ' , cmdline]);
        end
    end

    methods (Static, Hidden)

        function ret = getBuildCommand(~,~)
            ret = 'build';
        end

        function [LocalPythonPath, ActivatePath, PyEnvDir] = setupPythonAndCmakeTools(forceRecreateVENV)
            [LocalPythonPath, ActivatePath, PyEnvDir] = ros.ros2.internal.createOrGetLocalPython(forceRecreateVENV);
        end

        function cmkminver = getCMAKEMinimumVersion()
            cmkminver = ros.ros2.internal.ColconBuilder.CMAKEMINVERSION;
        end

        function dotPrintObj = createDotPrinter()
            dotPrintObj = ros.internal.DotPrinter('ros:mlros2:util:RunningColconCmd', strrep(pwd,'\','/'));
        end

        function retCmd = formatCommand(cmd)
            retCmd = [cmd ' --packages-select '];
        end

        function [aPath, aVersion] = getCMakePath()
            [aPath, aVersion] = ros.internal.utilities.getCMakeBinaryPath(ros.ros2.internal.ColconBuilder.CMAKEMINVERSION);
        end

        function textProgressObj = createTextProgressBar()
            textProgressObj = ros.internal.TextProgressBar('ros:mlros2:util:RunningColconCmd', strrep(pwd,'\','/'));
        end
    end
end
