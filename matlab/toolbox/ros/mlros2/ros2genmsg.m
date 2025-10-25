function ros2genmsg(folderPath, varargin)
%ros2genmsg Generate custom messages from ROS 2 definitions
%   ros2genmsg(FOLDERPATH) generates MATLAB interfaces to ROS 2 custom
%   messages. FOLDERPATH is the path to a folder that contains the
%   definitions of the custom messages (.msg files). This function expects
%   one or more ROS 2 package folders inside the FOLDERPATH.
%
%   Building the message libraries requires Python and a C++ compiler. See
%   the ROS 2 Custom Messages documentation for more information.
%
%   ros2genmsg(FOLDERPATH,Name,Value) provides additional options
%   specified by one or more Name,Value pair arguments.
%
%      "BuildConfiguration"   - Allows for selecting different compiler
%                               optimizations when building the message
%                               libraries. Options are:
%                                  "fasterbuilds" - Prioritize reducing
%                                                   build and rebuild
%                                                   times. This is the
%                                                   default configuration.
%                                  "fasterruns"   - Prioritize speed of 
%                                                   execution using the
%                                                   libraries.
%
%       "CreateShareableFile" - Generates an archive file to share with
%                               others on the same platform and using the
%                               same MATLAB release version. Options are:
%                                  true           - It creates a zip file
%                                                   by compressing the
%                                                   install folder of the
%                                                   matlab_msg_gen folder.
%                                  false          - No zip file is created.
%                                                   This is the default
%                                                   configuration.
%      
% 
%   It is safe to call any of these functions multiple times. All messages under
%   FOLDERPATH will be rebuilt. It is also safe to switch between different
%   build configurations.
%
%   Built-in message types may be overwritten by calling ros2genmsg on a
%   directory with new message definition files for the built-in message
%   types.
%
%   After the messages are built, you can send and receive your custom
%   messages in MATLAB like any other supported messages. They can be
%   created using ros2message or viewed in the list of messages by calling
%   ros2 msg list.
%
%
%   Example:
%
%      % Create a custom message package folder in a local directory.
%      folderPath = fullfile(pwd,"ros2CustomMessages");
%      packagePath = fullfile(folderPath,"simple_msgs");
%      mkdir(packagePath)
% 
%      % Create a folder msg inside the custom message package folder.
%      mkdir(packagePath,"msg")
% 
%      % Create a .msg file inside the msg folder.
%      messageDefinition = {'int64 num'};
% 
%      fileID = fopen(fullfile(packagePath,'msg','Num.msg'),'w');
%      fprintf(fileID,'%s\n',messageDefinition{:});
%      fclose(fileID);
% 
%      % Create a folder srv inside the custom message package folder.
%      mkdir(packagePath,"srv")
% 
%      % Create a .srv file inside the srv folder.
%      serviceDefinition = {'int64 a'
%                           'int64 b'
%                           '---'
%                           'int64 sum'};
% 
%      fileID = fopen(fullfile(packagePath,'srv','AddTwoInts.srv'),'w');
%      fprintf(fileID,'%s\n',serviceDefinition{:});
%      fclose(fileID);
%
%      % Create a folder action inside the custom message package folder.
%      mkdir(packagePath,"action")
% 
%      % Create an .action file inside the action folder.
%      actionDefinition = {'int64 goal'
%                          '---'
%                          'int64 result'
%                          '---'
%                          'int64 feedback'};
% 
%      fileID = fopen(fullfile(packagePath,'action','Test.action'),'w');
%      fprintf(fileID,'%s\n',actionDefinition{:});
%      fclose(fileID);
%
%      % Generate custom messages from ROS 2 definitions in .msg, and .srv files.
%      ros2genmsg(folderPath)
%
%      % Generate custom messages and generate the zip file.
%      ros2genmsg(folderPath,CreateShareableFile=true)
%
%   See also ros2message, ros2.

% Copyright 2019-2024 The MathWorks, Inc.

% Input processing
    if nargin < 1
        folderPath = pwd;
    end
    folderPath = convertStringsToChars(folderPath);
    folderPath = ros.internal.Parsing.validateFolderPath(folderPath);
    
    %Parse inputs to function
    defaultValForBuild = 'fasterbuilds';
    defaultValForShare = false;
    defaultValForSuppressOutput = false;
    defaultValForUseNinja = true;

    parser = inputParser;

    addParameter(parser, 'BuildConfiguration', defaultValForBuild, ...
        @(x) validateStringParameter(x, ...
                                     {'fasterbuilds', 'fasterruns'},...
                                     'ros2genmsg',...
                                     'BuildConfiguration'));

    addParameter(parser, 'CreateShareableFile', defaultValForShare, ...
                         @(x) validateattributes(x, {'logical'}, {}, ...
                                     'ros2genmsg',...
                                     'CreateShareableFile'));

    addParameter(parser, 'SuppressOutput', defaultValForSuppressOutput, ...
                         @(x) validateattributes(x, {'logical'}, {}, ...
                                     'ros2genmsg',...
                                     'SuppressOutput'));
    addParameter(parser, 'UseNinja', defaultValForUseNinja, ...
                         @(x) validateattributes(x, {'logical'}, {}, ...
                                     'ros2genmsg',...
                                     'UseNinja'));
    
    function validateStringParameter(value, options, funcName, varName)
        % Separate function to suppress output and just validate
        validatestring(value, options, funcName, varName);
    end

    % Parse the input and assign outputs
    parse(parser, varargin{:});

    %Extract full matched value if there was a partial match
    buildConfiguration = validatestring(parser.Results.BuildConfiguration, ...
                                        {'fasterbuilds', 'fasterruns'});
    createShareableFile = parser.Results.CreateShareableFile;

    suppressOutput = parser.Results.SuppressOutput;
    useNinja = parser.Results.UseNinja;

    %get ros2 install dir
    amentPrefixPath = ros.ros2.internal.getAmentPrefixPath;
    ros2msgSrcPathRoot = fullfile(amentPrefixPath,'share');

    pkgDirs = ros.internal.custommsgs.getPkgDirs(folderPath);
    modifiedFolderPath = strrep(folderPath,'\','/');

    if isequal(suppressOutput, false)
        dotprinter = ros.internal.DotPrinter('ros:utilities:util:IdentifyingMessages', modifiedFolderPath); %#ok<NASGU>
    end
    pkgInfos = cell(1,numel(pkgDirs));
    if isempty(pkgInfos)
        error(message('ros:utilities:custommsg:NoPackage', folderPath));
    end

    % Use custom message registry constants for consistency between tools
    customRegistry = ros.internal.CustomMessageRegistry.getInstance('ros2', true);
    customRegistry.refresh(true);
    
    % Get the Additional custom message directories if there are any.
    customInstallDirs = fullfile(fileparts(customRegistry.getBinDirList));
    if ~iscell(customInstallDirs)
        customInstallDirs = {customInstallDirs};
    end
    customROSMessageShareDir = fullfile(customInstallDirs,'share');
    msgFilesDirs = [{folderPath}, customROSMessageShareDir ,{ros2msgSrcPathRoot}];

    % Place where we will generate cpp files
    msgFullName = {};
    srvFullName = {};
    srvFullNameRequest = {};
    srvFullNameResponse = {};
    actionFullName = {};
    actionFullNameGoal = {};
    actionFullNameResult = {};
    actionFullNameFeedback = {};

    if isequal(suppressOutput, false)
        dotprinter = ros.internal.DotPrinter('ros:utilities:util:ValidatingMessages', modifiedFolderPath); %#ok<NASGU>
    end

    [pkgMsgFiles, pkgSrvFiles, pkgActionFiles] = ros.internal.custommsgs.checkValidityOfMessages(pkgDirs,folderPath,'ros2', pkgInfos);
    ros.ros2.internal.validateMsg(folderPath);

    clear dotprinter;

    ros.ros2.internal.createOrGetLocalPython(); %ensure python is available
    
    %for pkg we will create two packages
    includeDirs = { fullfile(matlabroot, 'extern','include'), ...
                    fullfile(matlabroot, 'extern','include','MatlabDataArray'), ...
                    fullfile(matlabroot, 'toolbox','ros','include','ros2') };
    [libDirs, libMap] = ros.internal.custommsgs.getLibInfo;

    libRos2DirsMap = containers.Map({'win64','maci64', 'maca64','glnxa64'}, ...
                                    { ...
                                        fullfile(matlabroot,'sys','ros2','win64','ros2','lib') ...
                                        fullfile(matlabroot,'sys','ros2','maci64','ros2','lib'),...
                                        fullfile(matlabroot,'sys','ros2','maca64','ros2','lib'),...
                                        fullfile(matlabroot,'sys','ros2','glnxa64','ros2','lib')...
                   });

    libRos2Dirs = libRos2DirsMap(computer('arch'));
    librclcpp_action = containers.Map({'win64','maci64', 'maca64','glnxa64'},...
                                {...
                                    fullfile(libRos2Dirs,'rclcpp_action.lib'),...
                                    fullfile(libRos2Dirs,'librclcpp_action.dylib'),...
                                    fullfile(libRos2Dirs,'librclcpp_action.dylib'),...
                                    fullfile(libRos2Dirs,'librclcpp_action.so')...
                   });

    if isunix && ~ismac
        linkLibraries = {fullfile(matlabroot, 'sys','os','glnxa64','orig','libstdc++.so.6'), libMap(computer('arch'))};
    else
        linkLibraries = {libMap(computer('arch'))};
    end

    % Location where all files will be modified
    genDir = fullfile(folderPath, 'matlab_msg_gen', computer('arch'));
    [status, errorMsg, errorMsgId] = mkdir(genDir);
    if ~status && ~isequal(errorMsgId, 'MATLAB:MKDIR:DirectoryExists')
        error(errorMsgId, errorMsg);
    end

    %create an empty COLCON_IGNORE so it does not reread by colcon
    colconIgnorePath = fullfile(folderPath,'matlab_msg_gen','COLCON_IGNORE');
    catkinIgnorePath = fullfile(folderPath,'matlab_msg_gen','CATKIN_IGNORE');
    if ~isfile(colconIgnorePath)
        [fID, errorMsg] = fopen(colconIgnorePath,'w');
        assert(fID >= 0, message('ros:utilities:custommsg:CreateColconIgnore', colconIgnorePath, errorMsg));
        fclose(fID);
    end

    if ~isfile(catkinIgnorePath)
        [fID, errorMsg] = fopen(catkinIgnorePath,'w');
        assert(fID >= 0, message('ros:utilities:custommsg:CreateCatkinIgnore', catkinIgnorePath, errorMsg));
        fclose(fID);
    end

    builder = ros.ros2.internal.ColconBuilder.empty;
    if isequal(suppressOutput, false)
        msgGenProgress = ros.internal.TextProgressBar('ros:utilities:util:GenMATLABInterfaceInProgress');
        msgGenProgress.printProgress(0,numel(pkgDirs)); %initialize progress with 0%
    end
    
    % Generate publisher and subscriber files, and MATLAB interfaces
    for iPkg = 1:numel(pkgDirs)
        msgFiles = pkgMsgFiles{iPkg};
        srvFiles = pkgSrvFiles{iPkg};
        actionFiles = pkgActionFiles{iPkg};
        pkgInfos{iPkg} = ros.internal.PackageInfo(pkgDirs{iPkg}, ...
                                                  'cppLibraryName', [pkgDirs{iPkg} '_matlab'], ...
                                                  'libFormat', 'SHARED', ...
                                                  'includeDirs', includeDirs, ...
                                                  'libDirs', {libDirs}, ...
                                                  'libs', linkLibraries, ...
                                                  'matlabDestPath', fullfile('m','+ros','+internal','+ros2','+custommessages',['+' pkgDirs{iPkg}]), ...
                                                  'dependencies', {'class_loader', 'console_bridge', 'rclcpp', 'rcutils'});
        %TODO: Read package.xml in that directory for other properties (g1998282)

        % Set up folders for MATLAB file generation
        if iPkg == 1
            builder = ros.ros2.internal.ColconBuilder(genDir, pkgInfos{iPkg}, UseNinja=useNinja, SuppressOutput=suppressOutput);
        else
            addPackage(builder, pkgInfos{iPkg});
        end

        % Md5checksum.mat - contains cached values of checkSumMap which is
        % reused for smart build of ros2genmsg if there is a change in few message definitions.
        msgMd5ChecksumStoragePath = fullfile(builder.RootDir,'src',pkgDirs{iPkg},'Md5checksum.mat');
        generateFiles = ~isfile(msgMd5ChecksumStoragePath);
        [pkgDir, srcGenDir, pkgMsg, pkgSrv, pkgAction, structGenDir] = createPackageFolder(builder, pkgInfos{iPkg}.PackageName, generateFiles);

        %refMsgTypeCheckSumMap - contains the calculated Md5 values in current build.
        %checkSumMap - contains Md5 values calculated during previous build (used in case of rebuild).
        refMsgTypeCheckSumMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
        checkSumMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
        registry = ros.internal.CustomMessageRegistry.getInstance('ros2');

        %if Md5checksum.mat exists, load checkSumMap variable into
        %the current workspace
        if isfile(msgMd5ChecksumStoragePath)
           load(msgMd5ChecksumStoragePath, 'checkSumMap');
        end

        for iMsg = 1:numel(msgFiles)
            [~, msgName] = fileparts(msgFiles(iMsg).name);
            msgFullName{end+1} = [pkgDirs{iPkg} '/' msgName]; %#ok<AGROW>

            % If we want to update any built-in message, preference should be given to the custom message directory first.
            [genFiles, dependencies] = ros.internal.pubsubEmitter(msgFullName{end}, ...
                                                              msgFilesDirs, ...
                                                              'ros2', refMsgTypeCheckSumMap, registry, checkSumMap,...
                                                              srcGenDir, structGenDir, structGenDir);
            %remove this pkgName from dependencies
            dependencies = setdiff(dependencies,pkgDirs{iPkg});
            for i = 1:numel(genFiles)
                [~,~,fext] = fileparts(genFiles{i});
                if isequal(fext,'.cpp')
                    pkgInfos{iPkg}.LibSourceFiles = [pkgInfos{iPkg}.LibSourceFiles {fullfile(srcGenDir,genFiles{i})}];
                elseif isequal(fext,'.m')
                    pkgInfos{iPkg}.MATLABFiles = [pkgInfos{iPkg}.MATLABFiles genFiles(i)];
                end
            end
            pkgInfos{iPkg}.MessageFiles = [ pkgInfos{iPkg}.MessageFiles {fullfile(msgFiles(iMsg).folder,msgFiles(iMsg).name)} ];
            for i = 1:numel(dependencies)
                dependency = fileparts(dependencies{i});
                if ~isequal(dependency, pkgDirs{iPkg})   % Avoid reflective dependencies
                    pkgInfos{iPkg}.Dependencies = unique([ pkgInfos{iPkg}.Dependencies {dependency} ]);
                    pkgInfos{iPkg}.MsgDependencies = unique([ pkgInfos{iPkg}.MsgDependencies {dependency} ]);
                end
            end
        end
        
        for iSrv = 1:numel(srvFiles)
            [~, srvName] = fileparts(srvFiles(iSrv).name);
            srvFullName{end+1} = [pkgDirs{iPkg} '/' srvName]; %#ok<AGROW>
            srvFullNameRequest{end+1} = [srvFullName{end} 'Request']; %#ok<AGROW>
            srvFullNameResponse{end+1} = [srvFullName{end} 'Response']; %#ok<AGROW>

            % If we want to update any built-in message, preference should be given to the custom message directory first.
            [genFiles, requestDependencies, responseDependencies] = ros.internal.clientserverEmitter(...
                srvFullName{end}, msgFilesDirs, ...
                'ros2', refMsgTypeCheckSumMap, registry, checkSumMap, srcGenDir, structGenDir, structGenDir);

            dependencies = union(requestDependencies,responseDependencies);
            %remove this pkgName from dependencies
            dependencies = setdiff(dependencies,pkgDirs{iPkg});
            for i = 1:numel(genFiles)
                [~,~,fExt] = fileparts(genFiles{i});
                if isequal(fExt,'.cpp')
                    pkgInfos{iPkg}.LibSourceFiles = [pkgInfos{iPkg}.LibSourceFiles {fullfile(srcGenDir,genFiles{i})}];
                elseif isequal(fExt,'.m')
                    pkgInfos{iPkg}.MATLABFiles = [pkgInfos{iPkg}.MATLABFiles genFiles(i)];
                end
            end
            pkgInfos{iPkg}.ServiceFiles = [ pkgInfos{iPkg}.ServiceFiles {fullfile(srvFiles(iSrv).folder,srvFiles(iSrv).name)} ];
            for i = 1:numel(dependencies)
                dependency = fileparts(dependencies{i});
                if ~isequal(dependency, pkgDirs{iPkg})   % Avoid reflective dependencies
                    pkgInfos{iPkg}.Dependencies = unique([ pkgInfos{iPkg}.Dependencies {dependency} ]);
                    pkgInfos{iPkg}.MsgDependencies = unique([ pkgInfos{iPkg}.MsgDependencies {dependency} ]);
                end
            end
        end

        for iAction = 1:numel(actionFiles)
            [~, msgName] = fileparts(actionFiles(iAction).name);
            actionFullName{end+1} = [pkgDirs{iPkg} '/' msgName]; %#ok<AGROW>
            actionFullNameGoal{end+1} = [actionFullName{end} 'Goal']; %#ok<AGROW>
            actionFullNameResult{end+1} = [actionFullName{end} 'Result']; %#ok<AGROW>
            actionFullNameFeedback{end+1} = [actionFullName{end} 'Feedback']; %#ok<AGROW>
            [genFiles, goalDependencies, resultDependencies, feedbackDependencies] = ros.internal.actionEmitter(...
                actionFullName{end}, msgFilesDirs, ...
                'ros2', refMsgTypeCheckSumMap,registry,checkSumMap, ...
                srcGenDir, structGenDir, structGenDir);
            dependencies = union(goalDependencies,resultDependencies);
            dependencies = union(dependencies,feedbackDependencies);

            %remove this pkgName from dependencies
            dependencies = setdiff(dependencies,pkgDirs{iPkg});
            for i = 1:numel(genFiles)
                [~,~,fExt] = fileparts(genFiles{i});
                if isequal(fExt,'.cpp')
                    pkgInfos{iPkg}.LibSourceFiles = [pkgInfos{iPkg}.LibSourceFiles {fullfile(srcGenDir,genFiles{i})}];
                elseif isequal(fExt,'.m')
                    % Generated ROS message struct functions have different name
                    pkgInfos{iPkg}.MATLABFiles = [pkgInfos{iPkg}.MATLABFiles genFiles(i)];
                end
            end
            pkgInfos{iPkg}.ActionFiles = [ pkgInfos{iPkg}.ActionFiles {fullfile(actionFiles(iAction).folder,actionFiles(iAction).name)} ];
            for i = 1:numel(dependencies)
                dependency = fileparts(dependencies{i});
                if ~isequal(dependency, pkgDirs{iPkg})   % Avoid reflective dependencies
                    pkgInfos{iPkg}.Dependencies = unique([ pkgInfos{iPkg}.Dependencies {dependency} ]);
                    pkgInfos{iPkg}.MsgDependencies = unique([ pkgInfos{iPkg}.MsgDependencies {dependency} ]);
                end
            end
            pkgInfos{iPkg}.Dependencies = unique([ pkgInfos{iPkg}.Dependencies {'action_msgs', 'builtin_interfaces', 'unique_identifier_msgs'} ]);
            pkgInfos{iPkg}.MsgDependencies = unique([ pkgInfos{iPkg}.MsgDependencies {'action_msgs', 'builtin_interfaces', 'unique_identifier_msgs'} ]);
            pkgInfos{iPkg}.Libraries = [linkLibraries {librclcpp_action(computer('arch'))}];
        end

        %copy msg and srv files from package directory to
        %matlab_msg_gen path and create package.xml, CMakeLists.txt
        %and visibility_control.h files from templates.
        updateFilesInPath(builder, pkgDir, pkgInfos{iPkg}, pkgMsg, pkgSrv, pkgAction, generateFiles);

        %update the Md5 values of current build in checkSumMap
        checkSumMap = refMsgTypeCheckSumMap;
        save(msgMd5ChecksumStoragePath, 'checkSumMap');
        if isequal(suppressOutput, false)
            msgGenProgress.printProgress(iPkg, numel(pkgDirs));
        end
    end

    ament_prefix_path = amentPrefixPath;    

    %Append CMAKE PREFIX PATH with additional custom messages folder
    for dirIndex = 1:length(customInstallDirs)
        customInstallDirs{dirIndex} = strrep(customInstallDirs{dirIndex},'\','/');
        ament_prefix_path = [strrep(customInstallDirs{dirIndex},'\','/') pathsep ament_prefix_path]; %#ok<AGROW>
    end

    % Build the messages
    colconMakeArgsMap = containers.Map();

    %Flags for Faster Builds, Faster Runs and Debug build configurations.
    switch (buildConfiguration)
        case {'fasterruns'}
            %Build with FasterRuns support
            config = ' -DCMAKE_BUILD_TYPE=Release';
            optimizationFlagsForWindows = ' -DCMAKE_CXX_FLAGS_RELEASE="/MD /O2 /Ob2 /DNDEBUG" ';
            optimizationFlagsForUnix = ' -DCMAKE_CXX_FLAGS_RELEASE=-O3 ';
            %case {'debug'}
            %%Debug Builds
            %config = ' -DCMAKE_BUILD_TYPE=Debug';
            %optimizationFlagsForWindows = ' -DCMAKE_CXX_FLAGS_DEBUG="/MDd /Zi /Ob0 /Od /RTC1" ';
            %optimizationFlagsForUnix = ' -DCMAKE_CXX_FLAGS_DEBUG=-g ';
        otherwise
            %Build with FasterBuilds support by default
            config = ' -DCMAKE_BUILD_TYPE=Release';
            optimizationFlagsForWindows = ' -DCMAKE_CXX_FLAGS_RELEASE="/MD /Od /Ob2 /DNDEBUG" ';
            optimizationFlagsForUnix = ' -DCMAKE_CXX_FLAGS_RELEASE=-O0 ';
    end


    customRMWReg = ros.internal.CustomRMWRegistry.getInstance();
    customRMWRegList = customRMWReg.getRMWList();
    if ismember('rmw_ecal_proto_cpp',customRMWRegList)
        rmwInfo = customRMWReg.getRMWInfo('rmw_ecal_proto_cpp');
        builder.setUseNinja(false);
        middlewareHomeBinVal = fullfile(rmwInfo.middlewarePath,'bin');
        config = [config ' -DProtobuf_PROTOC_EXECUTABLE=' ['"' fullfile(middlewareHomeBinVal,'protoc.exe') '" ']];
    end

    [resetEnvs, resetCustomAmentPrefPath, ...
        resetCustomPath, resetCustomSitePkgsPath, restCustomLibraryPath] = ros.ros2.internal.setCustomPathsAndMiddlewareEnv(ament_prefix_path); %#ok<ASGLU>

    if ispc
        colconMakeArgsMap('win64')   = [' --cmake-args', config,' -DBUILD_TESTING=OFF ', ...
            ' -DALIAS_ROS2_TF2=1 ',  optimizationFlagsForWindows];
    elseif ismac
        colconMakeArgsMap(computer('arch')) = [' --cmake-args', config,' -DBUILD_TESTING=OFF ',' -DALIAS_ROS2_TF2=1 ', optimizationFlagsForUnix];
    else
        colconMakeArgsMap(computer('arch')) = [' --cmake-args', config,' -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-no-as-needed" ',' -DBUILD_TESTING=OFF ',' -DALIAS_ROS2_TF2=1 ', optimizationFlagsForUnix];
    end
    colconMakeArgs = colconMakeArgsMap(computer('arch'));
    %build packages with colcon
     %other messages might need to be present in the same directory
    if isequal(suppressOutput, false)
        buildPackage(builder, [], ' --merge-install', colconMakeArgs);
    else
        result = buildPackage(builder, [], ' --merge-install', colconMakeArgs);
        buildResultMap = containers.Map;
        buildResultMap('BuildResult') = result;
        buildResultStorageMapPath = fullfile(genDir,'BuildResult.mat');
        save(buildResultStorageMapPath, 'buildResultMap');
    end

    % Update preferences with folder information
    reg = ros.internal.custommsgs.updatePreferences(msgFullName,srvFullNameRequest,srvFullNameResponse,srvFullName,actionFullName,'ros2',genDir); %#ok<NASGU>

    %Clear the persistent map for ROS2.
    msgMapROS2 = ros.internal.utilities.getPersistentMapForROS2('clear'); %#ok<NASGU>
    ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType('','clear');

    versionStorageMap = containers.Map;
    versionStorageMapPath = fullfile(builder.RootDir,'src','VersionInfo.mat');
    msgFullName = [msgFullName actionFullNameGoal actionFullNameResult actionFullNameFeedback];

    %Store the Release information, MessageTypes and ServiceTypes into a MAT
    %file. This information can be used when customers want to share these
    %generated custom messages to other machines.
    versionStorageMap('Release') = version('-release');
    versionStorageMap('Platform') = computer('arch');
    versionStorageMap('MessageList') = msgFullName;
    versionStorageMap('ServiceList') = srvFullName;
    versionStorageMap('ServiceRequestList') = srvFullNameRequest;
    versionStorageMap('ServiceResponseList') = srvFullNameResponse;
    versionStorageMap('ActionList') = actionFullName;
    save(versionStorageMapPath,'versionStorageMap')

    if isequal(createShareableFile,true)
        for i = 1:numel(pkgDirs)
            pkgsToZip{i} = fullfile(folderPath,pkgDirs{i}); %#ok<AGROW>
        end

        outZipFile = fullfile(folderPath,'matlab_msg_gen.zip');
        if isequal(suppressOutput, false)
            dotprinter = ros.internal.DotPrinter('ros:utilities:util:GenZipFile', modifiedFolderPath); %#ok<NASGU>
        end
        %Compressing the packages and the generated matlab_msg_gen folder to a
        %zip file. We can share this zip file to others.
        zip(outZipFile,[pkgsToZip,{fullfile(folderPath,'matlab_msg_gen',computer('arch'),'src','VersionInfo.mat')},{fullfile(folderPath,'matlab_msg_gen',computer('arch'),'install')}]);
        clear dotprinter;
    end
end
