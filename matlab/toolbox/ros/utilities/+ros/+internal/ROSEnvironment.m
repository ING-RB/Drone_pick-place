classdef ROSEnvironment < matlab.mixin.SetGet & ros.internal.mixin.ROSInternalAccess
    %ROSENVIRONMENT Manage ROS 3P environment
    %   Detailed explanation goes here
  
    %  Copyright 2022-2023 The MathWorks, Inc.
    properties
        VenvRoot(1,:) char
        PythonExecutable(1,:) char
    end

    properties (Dependent, SetAccess = private)
        ROS1VenvRoot
        ROS1PythonExecutable
        ROS2VenvRoot
        ROS2PythonExecutable
    end

    properties (Access = ?ros.internal.mixin.ROSInternalAccess)
        MATLABOnlineHelper(1,1) ros.internal.utilities.MATLABOnlineHelperInterface = ros.internal.utilities.MATLABOnlineHelper;
    end
    
    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        MinPythonVersion = '3.8'
        MaxPythonVersion = '3.11.0'
        PrefGroup = 'ROSToolbox'
        ROS1VenvRootPref = 'ROS1_VENV_ROOT'
        ROS2VenvRootPref = 'ROS2_VENV_ROOT'
        ROS1PythonExecutablePref = 'ROS1_PYTHON_EXECUTABLE'
        ROS2PythonExecutablePref = 'ROS2_PYTHON_EXECUTABLE'
        ROS1Packages = ["catkin_pkg", "empy", "docutils",...
            "pyparsing", "python_dateutil", "pyyaml",...
            "rosdep", "rosdistro", "rosinstall",...
            "rosinstall_generator", "rospkg", "setuptools",...
            "six", "vcstools", "wstool", "defusedxml"];
        ROS2Packages = ["colcon-common-extensions","argcomplete",...
            "lark-parser"];
        ROS1KeyPackage = 'catkin_pkg'
        ROS2KeyPackage = 'colcon_common_extensions'
    end

    methods
        function obj = ROSEnvironment(helper)
            %ROSEnvironment Construct an instance of this class
            if nargin > 0
                obj.MATLABOnlineHelper = helper;
            end
        end

        function venvRoot = get.ROS1VenvRoot(obj)
            if ispref(obj.PrefGroup,obj.ROS1VenvRootPref)
                venvRoot = getpref(obj.PrefGroup,obj.ROS1VenvRootPref);
            else
                venvRoot = '';
            end
        end

        function venvRoot = get.ROS2VenvRoot(obj)
            if ispref(obj.PrefGroup,obj.ROS2VenvRootPref)
                venvRoot = getpref(obj.PrefGroup,obj.ROS2VenvRootPref);
            else
                venvRoot = '';
            end
        end

        function pythonExecutable = get.ROS1PythonExecutable(obj)
            if ispref(obj.PrefGroup,obj.ROS1PythonExecutablePref)
                pythonExecutable = getpref(obj.PrefGroup,obj.ROS1PythonExecutablePref);
            else
                pythonExecutable = '';
            end
        end

        function pythonExecutable = get.ROS2PythonExecutable(obj)
            if ispref(obj.PrefGroup,obj.ROS2PythonExecutablePref)
                pythonExecutable = getpref(obj.PrefGroup,obj.ROS2PythonExecutablePref);
            else
                pythonExecutable = '';
            end
        end

        function set.VenvRoot(obj,venvRoot)
            % Empty value is allowed
            venvRoot = strtrim(convertStringsToChars(venvRoot));
            if ~isempty(venvRoot)
                obj.validateVenvRoot(venvRoot);
            end
            obj.VenvRoot = venvRoot;
        end

        function set.PythonExecutable(obj,pythonExe)
            % Empty value is allowed
            pythonExe = strtrim(convertStringsToChars(pythonExe));
            if ~isempty(pythonExe)
                obj.validatePythonExecutable(pythonExe);
            end
            obj.PythonExecutable = pythonExe;
        end

        function checkAndCreateVenv(obj,rosVersion,forceCreation)
            % Check and create venv if necessary
            rosVersion = validatestring(rosVersion,{'ros1','ros2'});
            if nargin < 3
                forceCreation = false;
            end
            
            % If not set, get defaults for Python executable and venv root
            pythonExe = getDefaultPythonExecutable(obj,rosVersion); % Does not throw exception
            if isempty(pythonExe)
                % Tell user to set Python executable using ROS Toolbox
                % preference panel
                error(message('ros:utilities:util:EmptyPythonExecutable'));
            end 
            venvRoot = getDefaultVenvRoot(obj,rosVersion);              

            % Detect change in virtual environment setup (executable +
            % venv root)
            if isequal(rosVersion,'ros1')
                forceCreation = forceCreation || ...
                    ~isequal(obj.ROS1PythonExecutable,pythonExe) || ...
                    ~isequal(obj.ROS1VenvRoot,venvRoot);
            else
                forceCreation = forceCreation || ...
                    ~isequal(obj.ROS2PythonExecutable,pythonExe) || ...
                    ~isequal(obj.ROS2VenvRoot,venvRoot);
            end

            % Create virtual environment
            if forceCreation || ~isValidVenv(obj,rosVersion)
                if isequal(rosVersion,'ros1')
                    packagesToInstall = obj.ROS1Packages;
                else
                    packagesToInstall = obj.ROS2Packages;
                end
                createVenv(obj,pythonExe,venvRoot,rosVersion,...
                    packagesToInstall);

                % Save ROS environment after successful creation of venv
                saveROSEnvironment(obj,rosVersion,pythonExe,venvRoot);
            end
        end

        function [pyExe,activatePath,venvDir] = getVenvInformation(obj,rosVersion)
            if isequal(rosVersion,'ros1')
                venvRoot = obj.ROS1VenvRoot;
            else
                venvRoot = obj.ROS2VenvRoot;
            end
            pyExe = obj.getPythonVenvExecutable(venvRoot,rosVersion);
            venvDir = obj.getVenvDir(venvRoot,rosVersion);
            activatePath = obj.getPythonActivatePath(venvRoot,rosVersion);        
        end
    end

    methods (Access = ?ros.internal.mixin.ROSInternalAccess)
        function valid = isValidVenv(obj,rosVersion)
            % Returns true if Python virtual environment is valid
            valid = false;

            % Check venv folder exists
            if isequal(rosVersion,'ros1')
                venvDir = obj.getVenvDir(obj.ROS1VenvRoot,rosVersion);
            else
                
                venvDir = obj.getVenvDir(obj.ROS2VenvRoot,rosVersion);
            end
            if ~isfolder(venvDir)
                return;
            end
            
            % find the last package that will be installed
            % if found, assuming all other packages installed properly
            keyPackage = getKeyPackage(obj,rosVersion);
            if ispc
                packageDir = fullfile(venvDir,'Lib','site-packages',keyPackage);
                found = isfolder(packageDir);
            else
                startSearch = fullfile(venvDir,'lib');
                startSearch = replace(startSearch, ' ', '\ ');
                [stat, res] = system(['find ' startSearch ' -type d -name ' keyPackage ' -print']);
                assert(stat == 0, res);
                found = ~isempty(res);
            end
            valid = valid || found;
        end       

        function createVenv(obj,pyExec,venvRoot,rosVersion,packagesToInstall)
            % Remove existing virtual environment
            venvDir = obj.getVenvDir(venvRoot,rosVersion);
            obj.removeVenv(venvDir);

            % In mac and Linux, users might have symbolic links. We need to find the
            % path: pyexec = char(py.os.path.realpath(pe.Executable));
            if ~ispc
                cmd = ['"' pyExec '" -c "import os.path; print(os.path.realpath(''' pyExec '''))"'];
                [stat, res] = system(cmd);
                if stat ~= 0
                    error(message('ros:utilities:util:ErrorCreatingPythonVenv',res));
                end
                pyExec = strtrim(res);
            end

            % Create Python virtual environment
            dotprinter = ros.internal.DotPrinter('ros:utilities:util:CreatingPythonVENV',rosVersion); %#ok<NASGU>           
            cmd = ['"' pyExec '" -m venv ' venvDir];
            if obj.MATLABOnlineHelper.isMATLABOnline
                % PIP is not installed in MATLAB Online. Initially create
                % VENV without pip and then bootstrap
                cmd  = [cmd '  --without-pip'];
            end
            [stat, res] = system(cmd); 
            if stat ~= 0
                error(message('ros:utilities:util:ErrorCreatingPythonVenv', res));
            end

            % For MAC, we need configs also
            if ismac
                [stat, res] = system(['cp ',fullfile(fileparts(pyExec),'python*-config'),...
                    ' ',fullfile(venvDir,'bin')]);
                if stat ~= 0
                    error(message('ros:utilities:util:ErrorCreatingPythonVenv',res));
                end
            end
            clear dotprinter;

            % Install PIP through boot-strapping on MATLAB online
            if obj.MATLABOnlineHelper.isMATLABOnline
                pipPath = fullfile(venvDir,'get-pip.py');
                try
                    websave(pipPath, obj.MATLABOnlineHelper.PipUrl);
                catch ex
                    error(message('ros:utilities:util:ErrorCreatingPythonVenv', ex.message));
                end
            end

            % Use local python in venv folder for activation
            activatePath = obj.getPythonActivatePath(venvRoot,rosVersion);
            pyVenvExec = obj.getPythonVenvExecutable(venvRoot,rosVersion);
            if ~isfile(pyExec)
                error(message('ros:utilities:util:ErrorCreatingPython3VenvPyexecNotFound',...
                    pyVenvExec,'ros.internal.preferences()'));
            end

            % Execute get-pip.py in MATLAB online to complete PIP
            % installation
            if obj.MATLABOnlineHelper.isMATLABOnline
                [stat, res] = system([pyVenvExec ' ' pipPath]);
                if stat ~= 0
                    error(message('ros:utilities:util:ErrorCreatingPythonVenv', res));
                end
            end

            % If not found install packages
            dotprinter = ros.internal.DotPrinter('ros:utilities:util:AddingReqdPackages'); %#ok<NASGU>
            if ispc
                cmdToRun = ['"' pyVenvExec ...
                    '" -m pip install --force --no-index --find-links="' ...
                    fullfile(matlabroot,'sys',rosVersion,'share','python') '" --find-links="' ...
                    fullfile(matlabroot,'sys',rosVersion,computer('arch'),'python') '" ' ...
                    char(join(packagesToInstall))];
            else
                %for some reason activate command does not have exec bit set
                [stat, res] = system(['chmod +x ' replace(activatePath,' ','\ ')]);
                assert(stat == 0, res);
                % Python package install command
                cmdToRun = ['sh -c ''' replace(pyVenvExec,' ','\ ') ...
                    ' -m pip install --no-index --find-links=' ...
                    fullfile(replace(matlabroot,' ','\ '),'sys',rosVersion,'share','python')...
                    ' --find-links=' ...
                    fullfile(replace(matlabroot,' ','\ '),'sys',rosVersion,computer('arch'),'python')...
                    ' ' char(join(packagesToInstall)) ''''];

                if ~obj.MATLABOnlineHelper.isMATLABOnline
                    % This is needed in Linux and MAC desktop platforms.
                    % Especially in MAC, pip and setuptools are sensitive
                    % to OS version and discrepancies in package name
                    % (spaces in package name etc.). Installing and earlier
                    % version of pip and setuptools fixes these issues.
                    cmd = ['sh -c ''' replace(pyVenvExec,' ','\ ') ...
                        ' -m pip install --no-index --find-links=' ...
                        fullfile(replace(matlabroot,' ','\ '),'sys',rosVersion,'share','python') ...
                        ' --find-links=' ...
                        fullfile(replace(matlabroot,' ','\ '),'sys',rosVersion,computer('arch'),'python')...
                        ' pip==24.3.1 setuptools==70.0.0'''];
                    [stat, res] = system(cmd);
                    if stat ~= 0
                        error(message('ros:utilities:util:ErrorInstallingPackages',res));
                    end
                end
            end
            [stat, res] = system(cmdToRun);
            if stat ~= 0
                error(message('ros:utilities:util:ErrorInstallingPackages', res));
            end
            clear dotprinter;

            % Copy files in Python include folder if nexcessary
            dotprinter = ros.internal.DotPrinter('ros:utilities:util:CopyingIncludeFolders'); %#ok<NASGU>
            pydestDirMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                { ...
                fullfile(venvDir,'Scripts'),...
                venvDir,...
                venvDir,...
                venvDir...
                });
            pydestDir = pydestDirMap(computer('arch'));
            filesInInclude = dir(fullfile(venvDir,'include'));
            if isempty(filesInInclude) || numel(filesInInclude) < 3
                pyIncludeDir = ros.internal.utilities.findPyIncludeDir(pyExec);
                if isempty(pyIncludeDir) || ~isfolder(pyIncludeDir)
                    if ~obj.MATLABOnlineHelper.isMATLABOnline
                        warning(message('ros:utilities:util:NoPythonIncludeDir',pyIncludeDir));
                    end
                else
                    [status, msg] = copyfile(pyIncludeDir,fullfile(pydestDir,'include'),'f');
                    if ~status
                        error(message('ros:utilities:util:ErrorCopyingFile',...
                            pyIncludeDir,fullfile(pydestDir,'include'),msg));
                    end
                end
            end
            clear dotprinter;

            % Copy libraries if needed
            dotprinter = ros.internal.DotPrinter('ros:utilities:util:CopyingLibraries'); %#ok<NASGU>
            destLibMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                { ...
                'python*.dll',...
                'libpython*.dylib',...
                'libpython*.dylib',...
                'libpython*.so'...
                });
            destMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                { ...
                fullfile(pydestDir,'libs'),...
                fullfile(pydestDir,'lib'),...
                fullfile(pydestDir,'lib'),...
                fullfile(pydestDir,'lib')...
                });
            dest = destMap(computer('arch'));
            filesInLib = dir(fullfile(dest,destLibMap(computer('arch'))));
            if isempty(filesInLib)
                pyLibDir = ros.internal.utilities.findPyLibDir(pyExec);
                if isempty(pyLibDir) || ~isfolder(pyLibDir)
                    if ~obj.MATLABOnlineHelper.isMATLABOnline
                        warning(message('ros:utilities:util:NoPythonLibDir',...
                            destLibMap(computer('arch'))));
                    end
                else
                    srcMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                        { ...
                        fullfile(pyLibDir,'*.*'),...
                        fullfile(pyLibDir,'libpython*.*'),...
                        fullfile(pyLibDir,'libpython*.*'),...
                        fullfile(pyLibDir,'libpython*.*')...
                        });
                    src = srcMap(computer('arch'));
                    if ~isempty(dir(src))
                        [status, msg] = copyfile(src,dest,'f');
                        if ~status
                            error(message('ros:utilities:util:ErrorCopyingFile',...
                                src,dest,msg));
                        end
                    end
                end
            end
            clear dotprinter;
        end

        function keyPackage = getKeyPackage(obj,rosVersion)
            if isequal(rosVersion,'ros1')
                keyPackage = obj.ROS1KeyPackage;
            else
                keyPackage = obj.ROS2KeyPackage;
            end
        end
    end

    methods (Hidden)
        function venvRoot = getDefaultVenvRoot(obj,rosVersion)
            % Return default venv root

            % Rules: 
            % 1. Use the obj.VenvRoot value set by the caller
            % 2. Use environment variable 'MY_PYTHON_VENV'
            % 3. Use value set in preferences
            % 4. Use automatically calculated value 
            if ~isempty(obj.VenvRoot)
                venvRoot = obj.VenvRoot;
                return
            end

            % Rule #2: fetch value from MY_PYTHON_VENV environment variable
            venvRoot = getenv('MY_PYTHON_VENV');
            if ~isempty(venvRoot)
                obj.validateVenvRoot(venvRoot);
                return
            end

            % Rule #3: Read saved value in preferences
            if isequal(rosVersion,'ros1')
                propName = 'ROS1VenvRoot';
            else
                propName = 'ROS2VenvRoot';
            end
            if ~isempty(obj.(propName))
                % Ensure existing directory is still valid. To be valid,
                % user must have read / write / execute privileges
                venvRoot = obj.(propName);
                [status,attrib] = fileattrib(venvRoot); % status = 0 if not folder
                if status && attrib.directory && ...
                        attrib.UserRead && attrib.UserWrite && ...
                        attrib.UserExecute
                    return
                end
            end

            % Rule #4: Automatic value
            if obj.MATLABOnlineHelper.isMATLABOnline
                % Create Python environment in temporary folder
                venvRoot = fullfile('/tmp','.matlab',['R' version('-release')]);
            else
                % Desktop version
                venvRoot = obj.getAutoVenvRootDir(prefdir);
            end
        end

        function validatePythonExecutable(obj,pythonExecutable)
            % Validate pythonExecutable points to a file
            if ~isfile(pythonExecutable)
                error(message('ros:utilities:util:InvalidPythonExecutable',pythonExecutable));
            end

            % Validate version
            [versionStr,versionValue] = obj.getPythonVersionValue(pythonExecutable);
            minVersionVal = ros.internal.utilities.getVersionVal(obj.MinPythonVersion);
            maxVersionVal = ros.internal.utilities.getVersionVal(obj.MaxPythonVersion);
            if (versionValue < minVersionVal) || (versionValue >= maxVersionVal)
                error(message('ros:utilities:util:InvalidPythonVersion',...
                    versionStr,'3.8.x','3.9.x','3.10.x'));
            end
        end

        function pythonExe = getDefaultPythonExecutable(obj,rosVersion)
            % Return default Python executable

            % Here are the rules:
            % 1. If obj.PythonExecutable is set return this value
            % 2. If MATLAB online use /usr/bin/python3 (v3.10.10 as of
            % R2023b)
            % 3. If obj.PythonExecutable is empty, use ROS1PythonExecutable or
            %   ROS2PythonExecutable saved in preferences
            % 4. If 1 & 2 fails, try pyenv 
            if ~isempty(obj.PythonExecutable)
                pythonExe = obj.PythonExecutable;
                return
            end

            % Rule #2: If MATLAB online use /usr/bin/python3 
            if obj.MATLABOnlineHelper.isMATLABOnline
                pythonExe = obj.MATLABOnlineHelper.PythonPath;
                return
            end

            % Rule #3: Read saved value in preferences
            if isequal(rosVersion,'ros1')
                propName = 'ROS1PythonExecutable';
            else
                propName = 'ROS2PythonExecutable';
            end
            if ~isempty(obj.(propName))
                pythonExe = obj.(propName);
                return
            end

            % Rule #4: Check existing Python environment
            pe = pyenv;
			
			% g3465010: Ensure that the Python executable path is not empty
            % If it is empty, return an empty string
            if strcmp(pe.Executable,"")
                pythonExe = '';
                return  
            end

            try
                exe = char(pe.Executable);
                obj.validatePythonExecutable(exe);
                pythonExe = char(exe);
                return;
            catch
            end

            % Use pyenv to set required version of Python. This works in
            % *nix platforms
            try
                cleanupObj = onCleanup(@() pyenv('Version',pe.Executable));
                newPe = pyenv('Version',obj.MinPythonVersion);
                exe = char(newPe.Executable);
                obj.validatePythonExecutable(exe);
                pythonExe = char(exe);
                return
            catch
            end
            pythonExe = '';
        end

        function saveROSEnvironment(obj,rosVersion,pythonExe,venvRoot)
            if isequal(rosVersion,'ros1')
                setpref(obj.PrefGroup,obj.ROS1VenvRootPref,venvRoot);
                setpref(obj.PrefGroup,obj.ROS1PythonExecutablePref,pythonExe);
            else
                setpref(obj.PrefGroup,obj.ROS2VenvRootPref,venvRoot);
                setpref(obj.PrefGroup,obj.ROS2PythonExecutablePref,pythonExe);
            end
        end

        function clearROSEnvironment(obj,rosVersion)
            if nargin < 2
                rosVersion = 'all';
            end
            switch (rosVersion)
                case 'ros1'
                    prefs = {obj.ROS1VenvRootPref,obj.ROS1PythonExecutablePref};
                case 'ros2'
                    prefs = {obj.ROS2VenvRootPref,obj.ROS2PythonExecutablePref};
                otherwise
                    prefs = {obj.ROS1VenvRootPref,obj.ROS1PythonExecutablePref,...
                        obj.ROS2VenvRootPref,obj.ROS2PythonExecutablePref};
            end
            prefExist = ispref(obj.PrefGroup,prefs);
            if any(prefExist)
                rmpref(obj.PrefGroup,prefs(prefExist));
            end
        end
    end

    methods (Static, Access = ?ros.internal.mixin.ROSInternalAccess)
        function venvRoot = getAutoVenvRootDir(venvRoot)
            % Windows and Linux
            if contains(venvRoot,' ')
                % User's prefdir has a space in the path
                if ispc
                    venvRoot = fullfile('C:\MATLAB',['R' version('-release')]);
                else
                    venvRoot = fullfile(getenv('HOME'),'.matlab',['R' version('-release')]);
                end
            end
        end

        function venvDir = getVenvDir(venvRoot,rosVersion)
            venvDir = fullfile(venvRoot,rosVersion,computer('arch'),'venv');
        end

        function pyExec = getPythonVenvExecutable(venvRoot,rosVersion)
            venvDir = ros.internal.ROSEnvironment.getVenvDir(venvRoot,rosVersion);
            if ispc
                pyExec = fullfile(venvDir,'Scripts','python.exe');
            else
                pyExec = fullfile(venvDir,'bin','python3');
            end
        end

        function activatePath = getPythonActivatePath(venvRoot,rosVersion)
            venvDir = ros.internal.ROSEnvironment.getVenvDir(venvRoot,rosVersion);
            if ispc
                activatePath = fullfile(venvDir,'Scripts','activate');
            else
                activatePath = fullfile(venvDir,'bin','activate');
            end
        end   
    
        function validateVenvRoot(venvRoot)
            % Validate venvRoot does not contain spaces. Python venv does
            % not work in a directory with spaces
            
            if ~isfolder(venvRoot)
                error(message('ros:utilities:util:InvalidFolder',venvRoot));
            end

            % Ensure user has read / write / execute privileges
            [status,attrib] = fileattrib(venvRoot);
            if status
                if ~attrib.UserRead
                    error(message('ros:utilities:util:InvalidPrivileges',venvRoot,'read'));
                elseif ~attrib.UserWrite
                    error(message('ros:utilities:util:InvalidPrivileges',venvRoot,'write'));
                elseif ~attrib.UserExecute
                    error(message('ros:utilities:util:InvalidPrivileges',venvRoot,'execute'));
                end
            end

            % Ensure no spaces in path
            if contains(venvRoot,' ')
                % This is developer error. User should never see this
                error(message('ros:utilities:util:NoSpaceInPythonVenvDir',venvRoot));
            end
        end

        function removeVenv(venvDir)
            if isfolder(venvDir)
                dotprinter = ros.internal.DotPrinter('ros:utilities:util:RemovingPreviousEnv'); %#ok<NASGU>
                attempts = 0;
                while isfolder(venvDir) && attempts < 20
                    status = rmdir(venvDir,'s');
                    attempts = attempts + 1;
                end
                if isfolder(venvDir) && ~status %still exist
                    ros.internal.utilities.rmdirusingsys(venvDir);
                end
                clear dotprinter;
            end
        end

        function [versionStr,versionValue] = getPythonVersionValue(pythonExe)
            [stat,result] = system([pythonExe ' --version']);
            if ~stat
                result = strsplit(result);
                versionStr = result{2};
                versionValue = ros.internal.utilities.getVersionVal(versionStr);
            else
                versionStr = '';
                versionValue = nan;
            end
        end
    end
end
