classdef (Abstract) ProjectTool < handle
% This class is for internal use only. It may be removed in the future.

% Project tool class for ROSProjectBuilder. Uses ROS ProjectBuilder object
% to create, build and run

% Copyright 2020-2024 The MathWorks, Inc.

    properties (Abstract, Constant)
        ProjectName
        ROSVersion
        DefaultDependencies
        % LinkReferenceLibraries Explicitly add dependent libraries from
        % the referenced model to target_link_libraries list
        LinkReferenceLibraries
    end

    methods (Abstract,Hidden)
        ret = getProjectData(obj);
        ret = getProjectBuilder(obj, anchorDir, pkgName, varargin);
        [res, installDir] = runBuildCommand(obj, context);
        ret = setROSControlPkgInfo(obj,mdlName,pkgInfo,srcFiles,incFiles);
        copyControllerPluginFiles(obj,anchorDir, pkgName, bDir);
    end

    methods
        function [ret, context] = initialize(h, buildInfo, context, varargin)
            ret = true;

            if isequal(buildInfo.getBuildName,'rtwshared')
                % Skip sharedutils - these will be covered by the
                % helper called in createProject
                return;
            end

            mycontext.modelName = buildInfo.getBuildName;
            % MLC_TARGET_NAME is added only for MATLAB codegen
            mycontext.isMDL = isempty(findBuildArg(buildInfo,'MLC_TARGET_NAME'));
            mycontext.anchorDir = buildInfo.Settings.LocalAnchorDir;
            mycontext.ActiveBuildConfiguration = context.ActiveBuildConfiguration;
            mycontext.isROSControlBuild = false;
            mycontext.isComponentBuild = false;
            mycontext.isExternalMode = false;

            % check for C++
            if mycontext.isMDL
                isModelRefSubDirectory = ros.codertarget.internal.Util.isRefModelSubDirectoryEnabled(mycontext.modelName);
                % Sanity check to ensure there is no more than one layer of
                % referenced models
                if isModelRefSubDirectory && ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                    if ros.codertarget.internal.Util.isDepthGreaterThanOne(mycontext.modelName)
                        modelRefNames = ros.codertarget.internal.Util.uniqueModelRefNames(buildInfo);
                        % Remove pre-generated tgz files
                        for k=1:numel(modelRefNames)
                            tgzArchive = fullfile(mycontext.anchorDir,[modelRefNames{k},'.tgz']);
                            if isfile(tgzArchive)
                                delete(tgzArchive)
                            end
                        end
                        % Throw error message in Simulink Diagnostic viewer
                        excp = MSLException([], message('ros:slros:cgen:RefModelExcessDepth', ...
                            mycontext.modelName));
                        throw(excp);
                    end
                end

                mycontext.ActiveBuildConfiguration = get_param(mycontext.modelName,'BuildConfiguration');
                lang = get_param(mycontext.modelName,'TargetLang');
                assert(isequal(lang,'C++'), ...
                       "ros:slros:cgen:CppLanguageRequired", ...
                       getString(message("ros:slros:cgen:CppLanguageRequired",lang)));
                mycontext.isROSControlBuild = ros.codertarget.internal.Util.isROSControlEnabled(mycontext.modelName);
                mycontext.isComponentBuild = ros.codertarget.internal.Util.isComponentLibProject(mycontext.modelName);
                % generate code-only if ROS Control generation is enabled
                % or user has explicitly set GenerateCodeOnly flag
                genCodeOnly = isequal(get_param(mycontext.modelName,'GenCodeOnly'), 'on');
                mycontext.isExternalMode = ros.codertarget.internal.Util.isTopLevelModel(buildInfo) && ...
                    ros.codertarget.internal.Util.isExternalModeBuild(buildInfo);
            else
                % Otherwise MATLAB Coder
                mycontext.ActiveBuildConfiguration = context.ActiveBuildConfiguration;
                genCodeOnly = false;
                [keys,vals]=buildInfo.getKeyValuePair('type','BuildArgs');
                genCodeOnlyIndex = find(strcmp(keys,'GEN_CODE_ONLY'));
                if ~isempty(genCodeOnlyIndex) && strcmp(vals{genCodeOnlyIndex},'1')
                    genCodeOnly = true;
                end
            end
            % code-generator changes the current working folder to build
            % folder

            pjtData = getProjectData(h);
            if ~isempty(pjtData)
                mycontext.ProjectData = pjtData;
            end
            
            % When skipLocalEnvCheck is true, it implies there is no need to 
            % verify local compilers. This is true when:
            % 1. Generate code without build on local machine
            % 2. Code generation for ROS/ROS 2 Control
            % 3. Code generation for ROS2 component
            % 4. Build on remote device
            isRemoteBuild = h.isRemoteBuild(mycontext);
            skipLocalEnvCheck = genCodeOnly || mycontext.isROSControlBuild || mycontext.isComponentBuild || isRemoteBuild;
            pkgName = h.getValidPackageName(mycontext.modelName);
            mycontext.projectBuilder = h.getProjectBuilder(mycontext.anchorDir, pkgName, 'GenCodeOnly', genCodeOnly, 'SkipLocalEnvCheck', skipLocalEnvCheck);
            context = mycontext;
        end

        function [ret, context] = createProject(h, buildInfo, context, varargin)
            import ros.codertarget.internal.Util
            type = varargin{2};
            comp = varargin{3};
            if type == coder.make.enum.BuildOutput.EXECUTABLE
                context.isLib            = false;
                context.isSharedUtil     = false;
            elseif type == coder.make.enum.BuildOutput.STATIC_LIBRARY
                context.isLib            = true;
                context.isSharedUtil     = ~isempty(strfind(comp.FinalProduct.TargetInfo.TargetFile, 'rtwshared')); %TODO CHECK
            else
                assert(false);
            end

            context.libs = {};
            context.Libraries = {};
            context.LibraryDirectories = {};
            libSize = length(comp.Libraries);


            if libSize > 1
                libs = comp.Libraries;
            elseif libSize == 1
                libs = {comp.Libraries};
            end

            archiveName = [context.modelName,'.tgz'];
            sDir = getSourcePaths(buildInfo, true, {'StartDir'});
            if isempty(sDir)
                sDir = {pwd};
            end
            archive = fullfile(sDir{1}, archiveName);

            if h.skipProjectGeneration(h.isRemoteBuild(context),archive,context)
                ret  = h.getValidPackageName(context.modelName);
                % skip project and archive generation if the generated
                % code has not changed
                disp(message('ros:slros:deploy:ArchiveUpToDate',context.modelName,archive).getString);
                return
            end

            % get pre-compiled libraries
            [context, linkOnlyObjs, preCompiledObjs] = Util.addLinkObjects(buildInfo,context);

            for i=1:libSize
                libstruct = libs{i};
                if ~isempty(libstruct.value)
                    % iterate over the libraries contained in value
                    % value is a cell-array of libraries
                    % We need to revisit this code when PIL/SIL is supported
                    % For SIL/PIL, we need to also consider the 'Type' field of
                    % libstruct.
                    for numLibs = 1:numel(libstruct.value)
                        pathToLib = buildInfo.formatPaths(libstruct.value{numLibs}, 'replaceStartDirWithRelativePath', true);
                        if ispc && endsWith(pathToLib,{'.o','.obj','.O','.OBJ'})
                            % Convert 8.3 path name to full path name
                            [~,libName,ext] = fileparts(builtin('_canonicalizepath',libstruct.value{numLibs}));
                        else
                            [~,libName,ext] = fileparts(libstruct.value{numLibs});
                        end
                        if  isequal(libName,'rtwshared') || ...
                                ismember([libName, ext], ...
                                         {preCompiledObjs.Name, linkOnlyObjs.Name})
                            % Shared utility source files are added to the
                            % referenced model project directly
                            continue;
                        end
                        if(coder.make.internal.isRelativePath(pathToLib))
                            context.libs{end+1} = fullfile('..',pathToLib);
                        else
                            context.libs{end+1} = fullfile(pathToLib);
                        end
                    end
                end
            end

            mdlName = buildInfo.getBuildName;
            %the following should always be true
            %verifying that they are and no accidents happened
            assert(isequal(context.modelName, mdlName));
            pkgName = h.getValidPackageName(mdlName);
            pkgInfo = context.projectBuilder.getPackageInfo(pkgName);
            pkgInfo = h.setPackageInfoFromContext(pkgInfo, context);
            pkgInfo.ModelName = mdlName;
            debugBuild = dictionary('win64','RelWithDebInfo',...
                'maci64','RelWithDebInfo',...
                'maca64','RelWithDebInfo',...
                'glnxa64','Debug');
            if h.isRemoteBuild(context)
                currArch = 'glnxa64';
            else
                currArch = computer('arch');
            end
            if strcmp(context.ActiveBuildConfiguration,'Debug') || ...
                    context.isExternalMode
                pkgInfo.BuildType = debugBuild(currArch);
            elseif strcmp(context.ActiveBuildConfiguration,'Specify')
                pkgInfo = h.setPackageInfoFromToolchain(pkgInfo, comp.ToolchainFlags);
            else
                pkgInfo.BuildType = 'Release';
            end
            
            % Create a cmake pkg-config parser object
            pkgInfo = Util.addPackageConfigModules(buildInfo,pkgInfo);

            % ignoreParseError converts parsing errors from
            % findIncludeFiles into warnings
            warnState = warning('off','RTW:buildInfo:unableToFindMinimalIncludes');
            try
                findIncludeFiles(buildInfo, ...
                                 'extensions', {'*.h' '*.hpp'}, ...
                                 'ignoreParseError', true);
            catch EX
                warning(warnState);
                rethrow(EX);
            end
            warning(warnState);

            defines = buildInfo.getDefines();
            [sharedSrcFiles, sharedIncFiles] = h.getSharedUtilsSources(buildInfo);
            srcFiles = unique([buildInfo.getSourceFiles(true,true), sharedSrcFiles]);
            incFiles = unique([buildInfo.getIncludeFiles(true,true), sharedIncFiles]);
            otherFiles = buildInfo.getFiles('other',true,true);
            % Remove defines.txt from the list
            otherFiles(contains(otherFiles,'defines.txt')) = [];
            % Remove mwboost - MATLAB boost SO/DYLIB/DLLs from being packaged
            otherFiles(contains(otherFiles,'mwboost_')) = [];

            % Cleanup include paths
            incPaths = buildInfo.getIncludePaths(true);

            % Filter build root directory
            incPathBuildRoot = cellfun(@(x)strcmp(x,context.projectBuilder.RootDir),incPaths);
            incPaths(incPathBuildRoot)=[];
            buildDirList = buildInfo.getBuildDirList;
            for i = 1:numel(buildDirList)
                incPaths = replace(incPaths,h.convertToUnixPath(buildDirList{i}),'');
                [~,buildDir,~] = fileparts(buildDirList{i});
                incPaths = replace(incPaths,['/',buildDir],'');
            end

            % Filter /codegen/exe folder (MATLAB Coder)
            codegenExeFolder = cellfun(@(x)startsWith(x,fullfile(context.projectBuilder.RootDir,'codegen','exe')),incPaths);
            incPaths(codegenExeFolder) = [];


            % Filter /toolbox/ros, /toolbox/target, /rtw, /simulink directories
            % Source files from the filtered directories will be copied in
            % a flat manner if there is any.
            internalDirs = {...
                            fullfile(matlabroot,'toolbox','ros'), ...
                            fullfile(matlabroot,'toolbox','target'), ...
                            fullfile(matlabroot,'rtw'), ...
                            fullfile(matlabroot,'simulink'), ...
                            };
            for dirIdx =1:numel(internalDirs)
                installedWithInternal = h.convertToUnixPath(internalDirs{dirIdx});
                incPathWithInternal = cellfun(@(x)startsWith(x,installedWithInternal),incPaths);
                incPaths(incPathWithInternal) = [];
            end

            % Filter extern/include directory
            % This should only filter top level extern/include. Toolboxes
            % using subfolder under extern/include will not be filtered.
            installedWithExternInc = h.convertToUnixPath(fullfile(matlabroot,'extern','include'));
            incPathWithExternInc = cellfun(@(x)strcmp(x,installedWithExternInc),incPaths);
            incPaths(incPathWithExternInc) = [];

            % Filter /slprj/ert/... folders
            incPaths(contains(incPaths,'/slprj/ert')) = [];

            % Filter /eml/externalDependency/... folders
            % Source code under those folders will be copied to
            % LibSourceFiles and to build directory. Hence don't need path 
            % information be specified in CMakeLists.txt.
            incPaths(contains(incPaths,'/eml/externalDependency')) = [];
            
            % Remove empty values
            incPaths = incPaths(~cellfun(@isempty,incPaths)); 

            concatDefines = sprintf('%s\n  ', defines{:});
            % get compile flags
            compFlags = getCompileFlags(buildInfo);
            concatCompileFlags = sprintf('%s  ', compFlags{:});
            pkgInfo.CppFlags = [pkgInfo.CppFlags concatDefines];
            if ~any(contains(srcFiles,'.cu'))
                % Append C++ compile flags from buildInfo for non-GPU code-gen only
                pkgInfo.CppFlags = [pkgInfo.CppFlags concatCompileFlags];
            end
            if isfield(context, 'ProjectData') && ...
                    isfield(context.ProjectData, 'GPUFlags')
                if isempty(context.ProjectData.GPUFlags)
                    pkgInfo.CUDAFlags = '-arch sm_50';
                else
                    pkgInfo.CUDAFlags = context.ProjectData.GPUFlags;
                end
            else
                pkgInfo.CUDAFlags = '-arch sm_50';
            end

            mdlRefLibraries = {};
            isModelRefSubDirectory = false;
            if context.isMDL
                isModelRefSubDirectory = ros.codertarget.internal.Util.isRefModelSubDirectoryEnabled(context.modelName);
                
                % Find all reference model includes
                commonMdlRefIncludes = {};
                modelRefNames = ros.codertarget.internal.Util.uniqueModelRefNames(buildInfo);
                if ~isempty(modelRefNames)
                    % Get all model ref paths
                    allMdlRefPaths = arrayfun(@(b)b.formatPaths(b.Path),buildInfo.ModelRefs,'UniformOutput',false);
                    % Get all model ref include files; for windows incFiles
                    % list has a mixture of '\' and '/' file-separators, so
                    % replace all '\' with '/'
                    mdlRefIncFiles = incFiles(contains(h.convertToUnixPath(incFiles),...
                        h.convertToUnixPath(allMdlRefPaths)));
                    commonMdlRefIncludes = mdlRefIncFiles;
                end
                % Exclude all reference model includes from ROS package buildInfo            
                incFiles = setdiff(incFiles, commonMdlRefIncludes);

                if ~isempty(modelRefNames) && isModelRefSubDirectory
                    pkgInfo.SubDirectories = h.getValidPackageName(modelRefNames);
                else
                    % Generate model-ref headers when not doing
                    % sub-directory project generation
                    mdlRefIncFiles = ros.codertarget.internal.Util.generateModelRefHeaders(buildInfo);
                    incFiles = [h.convertToUnixPath(mdlRefIncFiles), incFiles];
                end

                if (ros.codertarget.internal.Util.isTopLevelModel(buildInfo))
                    pkgInfo.TopLevelProjectName = h.getValidPackageName(mdlName);
                    % add referenced model libraries to target_link_libraries
                    if isModelRefSubDirectory
                        % Add the dependent libraries in sub-diretory
                        % proejct since they will not be added to
                        % target_dependencies
                        mdlRefLibraries = strcat('${MW_TOP_LEVEL_PROJECT_NAME}_', h.getValidPackageName(modelRefNames));
                    else
                        if h.LinkReferenceLibraries
                            % For ROS 2: find_package and ament_target_dependencies
                            % takes care of this
                            % For ROS 1: Explicit addition to
                            % target_link_libraries is needed
                            mdlRefLibraries = modelRefNames;
                        end
                    end
                end
            end

            if context.isROSControlBuild
                pkgInfo = h.setROSControlPkgInfo(mdlName,pkgInfo,srcFiles,incFiles);
            elseif context.isComponentBuild
                if context.isLib
                    pkgInfo.LibSourceFiles = srcFiles;
                    pkgInfo.LibIncludeFiles = incFiles;
                    if isModelRefSubDirectory 
                        pkgInfo.CppLibraryName = '${MW_TOP_LEVEL_PROJECT_NAME}_${PROJECT_NAME}';
                        pkgInfo.ExportedLibraryName = '${MW_TOP_LEVEL_PROJECT_NAME}_${PROJECT_NAME}';
                    else
                        pkgInfo.CppLibraryName = mdlName;
                    end
                    pkgInfo.LibFormat = 'SHARED';
                else
                    pkgInfo = ros.codertarget.internal.Util.setROSComponentPkgInfo(mdlName,pkgInfo,srcFiles,incFiles);
                end
            else
                if context.isLib
                    pkgInfo.LibSourceFiles = srcFiles;
                    pkgInfo.LibIncludeFiles = incFiles;
                    if isModelRefSubDirectory 
                        pkgInfo.CppLibraryName = '${MW_TOP_LEVEL_PROJECT_NAME}_${PROJECT_NAME}';
                        pkgInfo.ExportedLibraryName = '${MW_TOP_LEVEL_PROJECT_NAME}_${PROJECT_NAME}';
                    else
                        pkgInfo.CppLibraryName = mdlName;
                    end
                    if h.isRemoteBuild(context)
                        pkgInfo.LibFormat = '     ';
                    else
                        pkgInfo.LibFormat = 'STATIC';
                    end
                else
                    pkgInfo.SourceFiles = srcFiles;
                    pkgInfo.IncludeFiles = incFiles;
                    pkgInfo.CppNodeName = mdlName;
                end
            end

            if ~isempty(otherFiles)
                pkgInfo.OtherFiles = otherFiles;
            end
            if ~isempty(incPaths)
                pkgInfo.IncludeDirectories = unique([pkgInfo.IncludeDirectories incPaths]);
            end

            if context.isMDL && isModelRefSubDirectory && ~isempty(modelRefNames)
                for k=1:numel(modelRefNames)
                    pkgName = h.getValidPackageName(modelRefNames{k});
                    if ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                        % For top-level model include the referenced model
                        % include folders starting from current source dir
                        pkgInfo.IncludeDirectories{end+1} = ['${CMAKE_CURRENT_SOURCE_DIR}/',pkgName,'/include/',pkgName];
                    else
                        % For a refrenced model, referencing other models
                        % include folders one-path above the current source
                        % dir
                        pkgInfo.IncludeDirectories{end+1} = ['${CMAKE_CURRENT_SOURCE_DIR}/../',pkgName,'/include/',pkgName];
                    end
                end
            end

            %add dependencies based on context.libs
            if ~isempty(context.libs) && ~isModelRefSubDirectory
                [~,libNames,~] = cellfun(@(x)fileparts(x),context.libs,'UniformOutput',false);
                otherPkgs = replace(libNames,'_rtwlib','');
                pkgInfo.Dependencies = h.getValidPackageName(otherPkgs);
                %we do not expect any message dependencies as they had to be specified during rosXgenmsg
                %If there any they will come through when we build msgDepends
                %hence we are not adding them to MsgDependencies
            end

            if ~isempty(context.Libraries)
                pkgInfo.Libraries = unique([pkgInfo.Libraries context.Libraries]);
            end

            if ~isempty(context.LibraryDirectories)
                pkgInfo.LibraryDirectories = unique([pkgInfo.LibraryDirectories context.LibraryDirectories]);
            end
            % Append extra model-ref libraries, if any
            if ~isempty(mdlRefLibraries)
                % Skip for ROS 1 multiple pkg, we don't need to add it to
                % target_link_libraries. This will be added to
                % catkin_package in modelref CMaktLists.txt file instead.
                % (g2877404)
                if isa(context.projectBuilder, 'ros.internal.CatkinBuilder') ...
                        && ~isModelRefSubDirectory
                else
                    pkgInfo.Libraries =  [pkgInfo.Libraries mdlRefLibraries];
                end
            end
            if isfield(context,'ImportedLibs') && ~isempty(context.ImportedLibs)
                pkgInfo.ImportedLibraries = unique([pkgInfo.ImportedLibraries, context.ImportedLibs]);
            end


            if isfield(context,'LinkerFlags') && ~isempty(context.LinkerFlags)
                pkgInfo.LinkerFlags = ...
                    strjoin(unique([pkgInfo.LinkerFlags, ...
                                    context.LinkerFlags]));
            end

            msgDepends = {};
            msgDataStructArr = {};
            imageDepends = {};
            actionDep = h.getActionDependencies(buildInfo.getIncludeFiles(false, false));
            tfDep = h.getTransformationDependencies(buildInfo.getIncludeFiles(false, false));
            if isfield(context,'ProjectData')
                msgDataStructArr = h.getMsgInfoFromProjectData(context.ProjectData, h.ROSVersion);
                msgDepends = [msgDepends, cellfun(@(x)x.pkgName,msgDataStructArr, 'UniformOutput', false)];
                imageDepends = context.ProjectData.ImageDepends;
                msgDepends = [msgDepends, h.getROSTimeSteppingMsgDeps(context.ProjectData)];
            end
            
            pkgInfo.Dependencies = unique([pkgInfo.Dependencies, msgDepends, ...
                h.DefaultDependencies{:}, imageDepends, actionDep, tfDep]);

            if ~isempty(msgDepends)
                pkgInfo.MsgDependencies = unique([pkgInfo.MsgDependencies, msgDepends, actionDep]);
            end
            context.projectBuilder.updatePackage(pkgInfo);

            %now iterate through all publishers and subscribers and get any
            %custom messages
            customMsgMap = containers.Map(); %key: pkgName and value cell array of msgSrcs
            msgDependsMap = containers.Map(); %key: pkgName and value cell array of msg names that this model depends on in that package
            registry = ros.internal.CustomMessageRegistry.getInstance(h.ROSVersion);

            if isfield(context,'ProjectData') && ~isempty(msgDataStructArr)
                for i = 1:numel(msgDataStructArr)
                    msgDependsMap = ros.internal.utilities.findMsgDepends(...
                        [msgDataStructArr{i}.pkgName,'/',msgDataStructArr{i}.msgName], ...
                        msgDependsMap, ...
                        h.ROSVersion);
                end
                if isKey(msgDependsMap,'ros')
                    % ros/Time and ros/Duration are pseudo messages
                    msgDependsMap.remove('ros');
                end
                %from this get all dependent packages and messages
                depPkgs = msgDependsMap.keys;
                depMsgsWithPkgNames = {};
                for i = 1:numel(depPkgs)
                    depMsgsWithPkgNames = unique([depMsgsWithPkgNames cellfun(@(msgName)[depPkgs{i},'/',msgName], msgDependsMap(depPkgs{i}),'UniformOutput', false)]);
                end
                %append to allMsgInfo. This is super set of all msgInfos
                allMsgInfos = [msgDataStructArr cellfun(@(x)ros.internal.(h.ROSVersion).getMessageInfo(x, registry), depMsgsWithPkgNames,'UniformOutput',false)];
                customIdx = cellfun(@(x)x.custom,allMsgInfos,'UniformOutput',false);
                allCustomMsgInfos = allMsgInfos(cell2mat(customIdx));

                if h.isRemoteBuild(context) && ~isempty(allCustomMsgInfos) && ~context.projectBuilder.GenCodeOnly
                % When select to generate code only, do not validate custom
                % message on remote target
                    allRequiredCustomMsgs = {};
                    for customInfo = allCustomMsgInfos
                        allRequiredCustomMsgs{end+1} = customInfo{1}.msgCppClassName; %#ok<AGROW>
                    end
                    isMATLABCodegen = any(cellfun(@(x)contains(x,'structmsg_conversion.cpp'),buildInfo.getSourceFiles(true,true)));
                    [customMsgAvail, missingMsgs, remoteDir] = h.isCustomMsgsAvail(mdlName, allRequiredCustomMsgs, h.ROSVersion, isMATLABCodegen);
                    cgenInfoSL = ros.codertarget.internal.ROSSimulinkCgenInfo.getInstance;
                    if ~customMsgAvail && ~cgenInfoSL.getBuildMissingMsgs
                        if isMATLABCodegen
                            % For MATLAB Codegen, throw error message to
                            % command window
                            error(message('ros:slros:deploy:NoCustomMessage',missingMsgs,remoteDir));
                        else
                            % Throw error message and "Fixit" option to
                            % Simulink diagnostic viewer
                            mdlHandle = get_param(mdlName,'Handle');
                            diag = MSLException(mdlHandle, message('ros:utilities:util:NoCustomMessage', missingMsgs, remoteDir));
                            throw(diag);
                        end
                    end
                end

                processedCustomMsgPkg = {};
                for i = 1:numel(allCustomMsgInfos)
                    % add the packageName as key and message source as values
                    pkgName = allCustomMsgInfos{i}.pkgName;
                     % Process only once for each custom message package
                    if ~any(strcmp(processedCustomMsgPkg,pkgName))
                        processedCustomMsgPkg{end+1} = pkgName; %#ok<AGROW>
                        customMsgPkgPath = fileparts(fileparts(allCustomMsgInfos{i}.srcPath));
                        allMsgSrcs = h.getAllCustomMsgSrcFromPath(customMsgPkgPath);
                        for msgSrc = allMsgSrcs
                            if ~isempty(customMsgMap) && customMsgMap.isKey(pkgName)
                                curVal = customMsgMap(pkgName);
                                customMsgMap(pkgName) = unique([curVal, msgSrc{1}]);
                            else
                                customMsgMap(pkgName) = { msgSrc{1} };
                            end
                        end
                    end
                end
            end

            %for each entry in map, add a package with src
            pkgNames = customMsgMap.keys();
            for i = 1:numel(pkgNames)
                %for each package we should really look at the message and
                %recalculate the package dependencies.
                msgDependsMapForThisCustomPkg = containers.Map();
                msgsInThisCustomPkg = customMsgMap(pkgNames{i});
                % separate message and service files
                %from this get all dependent packages and messages
                for j = 1:numel(msgsInThisCustomPkg)
                    [~,msgName,ext] = fileparts(msgsInThisCustomPkg{j});
                    if strcmp(ext,'.srv')
                        reqMsg = [pkgNames{i},'/',msgName,'Request'];
                        respMsg = [pkgNames{i},'/',msgName,'Response'];
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(reqMsg,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(respMsg,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                    elseif strcmp(ext,'.action')
                        goalMsg = [pkgNames{i},'/',msgName,'Goal'];
                        feedbackMsg = [pkgNames{i},'/',msgName,'Feedback'];
                        resultMsg = [pkgNames{i},'/',msgName,'Result'];
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(goalMsg,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(feedbackMsg,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(resultMsg,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                    else
                        fullMsgName = [pkgNames{i},'/',msgName];
                        msgDependsMapForThisCustomPkg = ...
                            ros.internal.utilities.findMsgDepends(fullMsgName,...
                                                                  msgDependsMapForThisCustomPkg, h.ROSVersion);
                    end

                end
                if isKey(msgDependsMapForThisCustomPkg,'ros')
                    % ros/Time and ros/Duration are pseudo messages
                    msgDependsMapForThisCustomPkg.remove('ros');
                end
                dependencies = setdiff(msgDependsMapForThisCustomPkg.keys,pkgNames{i});
                idx = context.projectBuilder.findPackage(pkgNames{i});
                if ~isempty(idx)
                    pkgInfoMsg = context.projectBuilder.getPackage(pkgNames{i});
                    pkgInfoMsg = h.addMsgSources(pkgInfoMsg, msgsInThisCustomPkg);
                    if ~isempty(dependencies)
                        pkgInfoMsg.Dependencies = unique([pkgInfoMsg.Dependencies, dependencies]);
                        pkgInfoMsg.MsgDependencies = unique([pkgInfoMsg.MsgDependencies, dependencies]);
                    end
                    context.projectBuilder.updatePackage(pkgInfoMsg);
                else
                    pkgInfoMsg = ros.internal.PackageInfo(pkgNames{i});
                    pkgInfoMsg = h.addMsgSources(pkgInfoMsg, msgsInThisCustomPkg);
                    if ~isempty(dependencies)
                        pkgInfoMsg.Dependencies = unique([pkgInfoMsg.Dependencies, dependencies]);
                        pkgInfoMsg.MsgDependencies = unique([pkgInfoMsg.MsgDependencies, dependencies]);
                    end
                    context.projectBuilder.addPackage(pkgInfoMsg);
                end
            end

            %ensure we are not dependent on ourselves, msg could be in the
            %same package and ensure we are not adding pkgs that are
            %already in dep list
            pkgNamesFlt = pkgNames(~matches(pkgNames,pkgInfo.PackageName));
            if ~isempty(pkgNamesFlt)
                pkgInfo.Dependencies = unique([pkgInfo.Dependencies, pkgNamesFlt]);
                pkgInfo.MsgDependencies = unique([pkgInfo.MsgDependencies, pkgNamesFlt]);
            end
            context.pkgsToBuild = [pkgNamesFlt, pkgInfo.PackageName];

            context.projectBuilder.createPackage([],true); %force create package
            ret = pkgName;
            
            % create archive for remote build
            if context.isROSControlBuild
                bDir = getSourcePaths(buildInfo,true,{'BuildDir'});
                if isempty(bDir)
                    bDir = {pwd};
                end
                copyControllerPluginFiles(h,...
                    context.anchorDir,...
                    h.getValidPackageName(mdlName),...
                    bDir{1});
            end
            
            
            if context.isMDL  && isModelRefSubDirectory && ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                % Top-level model zip file will be created later for
                % modelref-subdirectory selection
            else
                % The zip file will be put in the start dir, the same as the final
                % executable or dll.
                disp(message('ros:slros:deploy:CreateArchiveFile', mdlName).getString);
                disp(ros.slros.internal.diag.DeviceDiagnostics.StepSeparator);
                tar(archive,fullfile(context.anchorDir,'src',{h.getValidPackageName(mdlName)}));
                disp(message('ros:slros:deploy:ArchiveTargetFile', archive).getString);
            end

            if context.isMDL && isModelRefSubDirectory && ~ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                % This is a model-reference build, this is not a top-level
                % model and the generated model should be in
                % model-reference sub-directory then delete the package
                % from the workspace folder
                pkgFolder = fullfile(context.anchorDir,'src',h.getValidPackageName(mdlName));
                if isfolder(pkgFolder)
                    % force delete the ref-model pkg from src/ folder
                    rmdir(pkgFolder,'s');
                end
            end

            if context.isMDL  && isModelRefSubDirectory && ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                % This is a model-reference build, this IS the top-level
                % model and the model-reference project should be in
                % sub-directory then extract the TGZ files from the anchor
                % dir to src/pkgname/ folder
                topPkgName = h.getValidPackageName(mdlName);
                toplevelPkgFolder = fullfile(context.anchorDir,'src', topPkgName);
                topPkgTgz = fullfile(context.anchorDir,[topPkgName '.tgz']);
                tempFolderCleanup = false;
                for k=1:numel(modelRefNames)
                    modelRefPkgName = modelRefNames{k};
                    tgzArchive = fullfile(context.anchorDir,[modelRefPkgName,'.tgz']);
                    if isfile(tgzArchive)
                        % Newly generated source folder for referenced
                        % model
                        if isfolder(fullfile(toplevelPkgFolder,modelRefPkgName))
                            % force delete the ref-model sub-directory if it
                            % exists
                            rmdir(fullfile(toplevelPkgFolder,modelRefPkgName),'s');
                        end
                        untar(tgzArchive,toplevelPkgFolder);
                        % Remove all ref-model tgz files
                        delete(tgzArchive);
                    elseif isfile(topPkgTgz)
                        % tgz file has been deleted, copy from previous
                        % genearted code
                        if (~tempFolderCleanup)
                            % Only need to untar once
                            untar(topPkgTgz,fullfile(context.anchorDir,'sl_ref_temp'));
							cleanup = onCleanup(@()rmdir(fullfile(context.anchorDir,'sl_ref_temp'),'s'));
                            tempFolderCleanup = true;
                        end
                        copyfile(fullfile(context.anchorDir,'sl_ref_temp',topPkgName,h.getValidPackageName(modelRefPkgName)),...
                                 fullfile(toplevelPkgFolder,h.getValidPackageName(modelRefPkgName)),'f');
                    end
                end
                % Create single tgz file
                disp(message('ros:slros:deploy:CreateArchiveFile', mdlName).getString);
                disp(ros.slros.internal.diag.DeviceDiagnostics.StepSeparator);
                tar(archive,fullfile(context.anchorDir,'src',{h.getValidPackageName(mdlName)}));
                disp(message('ros:slros:deploy:ArchiveTargetFile', archive).getString);
            end

            % create archive for remote build
            if h.isRemoteBuild(context)
                % Create zip file for custom message packages if needed
                cgenInfoSL = ros.codertarget.internal.ROSSimulinkCgenInfo.getInstance;
                customMsgPkgs = cgenInfoSL.getCustomMsgPkgName();
                if ~isempty(customMsgPkgs) && cgenInfoSL.getBuildMissingMsgs
                    for customMsgPkg = customMsgPkgs
                        if ~exist(fullfile(context.anchorDir,[customMsgPkg{1} '.tgz']),'file')
                            disp(ros.slros.internal.diag.DeviceDiagnostics.StepSeparator);
                            disp(message('ros:slros:deploy:CreateArchiveMsg', customMsgPkg{1}).getString);
                            disp(ros.slros.internal.diag.DeviceDiagnostics.StepSeparator);
                            tar(fullfile(sDir{1},[customMsgPkg{1} '.tgz']), fullfile(context.anchorDir,'src',customMsgPkg{1}));
                            disp(message('ros:slros:deploy:ArchiveTargetFile', customMsgPkg{1}).getString);
                        end
                    end
                end
                % Copy build_model.sh to the same directory as the archive file
                scriptName = ['build_',lower(h.ROSVersion),'_model.sh'];
                targetScript = fullfile(sDir{1}, scriptName);
                scriptLoc = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                copyfile(fullfile(scriptLoc,scriptName), targetScript, 'f');
                disp(message('ros:slros:deploy:ShellScriptTargetFile', targetScript).getString);
                disp(ros.slros.internal.diag.DeviceDiagnostics.StepSeparator);
                disp(message('ros:slros:deploy:CopyFilesToTarget').getString);
            end
        end

        function [ret, context] = buildProject(h, buildInfo, context, varargin)
            if h.isRemoteBuild(context)
                % Use LoadCommand and LoadCommandArgs from TargetSDK for
                % RemoteBuild
                % Skip buildProject
                ret = 'Success';
                return;
            end

            mdlName = buildInfo.getBuildName;
            if isequal(mdlName,'rtwshared')
                sharedutilsdir = ros.codertarget.internal.Util.sharedUtilsDir(buildInfo, true);
                % Create a dummy rtwshared.a file to avoid build errors
                sharedLibFile = fopen(fullfile(sharedutilsdir, 'rtwshared.a'),'w');
                fclose(sharedLibFile);
                ret = 'Success';
                return;
            end

            if context.isMDL && ros.codertarget.internal.Util.isRefModelSubDirectoryEnabled(context.modelName) ...
                 && ~ros.codertarget.internal.Util.isTopLevelModel(buildInfo)
                % When doing sub-directory code-generation we don't need to
                % invoke build for all the levels of code-generation, only
                % invoking build for the top-level model project is
                % sufficient
                ret = 'Success';
                return;
            end

            %the following should always be true
            %verifying that they are and no accidents happen
            assert(isequal(context.modelName, mdlName));
            pkgName = h.getValidPackageName(mdlName);
            pkgInfo = context.projectBuilder.getPackageInfo(pkgName); %#ok<NASGU>

            % Execute build command
            [res, installDir] = runBuildCommand(h, context);%#ok<ASGLU> %TO Consider: cat res into ret to show
            if context.isLib
                %we need to copy back to the current directory
                srcFileMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                    {fullfile(installDir,'lib',[mdlName,'.lib']), ... for windows
                    fullfile(installDir,'lib',['lib',mdlName,'.a']), ... for maci64
                    fullfile(installDir,'lib',['lib',mdlName,'.a']), ... for maca64
                    fullfile(installDir,'lib',['lib',mdlName,'.a'])}); ... for linux
                    if context.isMDL
                        destPath = fullfile(pwd,[mdlName,'_rtwlib.a']);
                    else
                        destPath = fullfile(pwd,[mdlName,'.a']);
                    end
                    [status, msg, msgId] = copyfile(srcFileMap(computer('arch')), ...
                        destPath);
                    if ~status
                        error(msgId,msg);
                    end
            end
            ret = 'Success';
        end

        function [ret, context] = downloadProject(h, buildInfo, context, varargin) %#ok<INUSL>
            ret = true;
            %TODO
        end

        function [ret, context] = runProject(h, buildInfo, context, varargin)%#ok<INUSL>
            ret = true;
            %TODO
        end

        function [ret, context] = onError(h, buildInfo, context, varargin)%#ok<INUSL>
            ret = true;
            try
                if ~context.isSharedUtil
                end
            catch %ignore all errors
            end
        end

        function [ret, context] = terminate(h, buildInfo, context, varargin) %#ok<INUSD>
            ret = true;
            context = [];
        end
    end

    methods (Static, Hidden)
        function skipGen =  skipProjectGeneration(isRemoteBuild, archive, context)
        % SKIPPROJECTGENERATION Skip generation of project and archive
        % if there was no structural change made to the Simulink model.
        % This method returns 'false' for MATLAB Coder ROS and ROS 2
        % projects.

            if isfield(context, 'ProjectData') && ...
                    isfield(context.ProjectData, 'HasCodeChanged')
                skipGen = ~context.ProjectData.HasCodeChanged && ...
                          isRemoteBuild && isfile(archive);
            else
                skipGen = false;
            end
        end

        function customMsgSrcs = getAllCustomMsgSrcFromPath(customPkgPath)
        %GETALLCUSTOMMSGSRCFROMPATH Get all custom message src from given path

            customMsgSrcs = {};
            % Get all messages from /msg folder
            getMsgFromFolder('msg');
            % Get all service from /srv folder
            getMsgFromFolder('srv');
            % Get all action from /action folder
            getMsgFromFolder('action');

            function getMsgFromFolder(ext)
                subDir = fullfile(customPkgPath, ext);
                subDirInfo = dir([subDir '/*.' ext]);
                if isfolder(subDir) && numel(subDirInfo)
                    for i=1:numel(subDirInfo)
                        customMsgSrcs{end+1} = fullfile(subDirInfo(i).folder,subDirInfo(i).name); %#ok<AGROW>
                    end
                end
            end
        end

        function pkgInfoMsg = addMsgSources(pkgInfoMsg, msgSources)
            % Initialize file arrays as empty cell array
            msgFiles = {}; srvFiles = {}; actFiles = {};

            if ~isempty(msgSources)
                % Get all message, service, and action under the same package
                % Get pkgDir, which may contains /msg, /srv, /action
                pkgDir = fileparts(fileparts(msgSources{1}));
                
                % Add all messages from /msg
                msgFiles = getFilePathsFromMsgPkgDir(msgFiles, 'msg');
                % Add all service from /srv
                srvFiles = getFilePathsFromMsgPkgDir(srvFiles, 'srv');
                % Add all action from /action
                actFiles = getFilePathsFromMsgPkgDir(actFiles, 'action');

                % Filter out actions from messages
                filterOutMsgs();
    
                % Add to package info
                if ~isempty(msgFiles)
                    pkgInfoMsg.MessageFiles = [pkgInfoMsg.MessageFiles,msgFiles];
                end
                if ~isempty(srvFiles)
                    pkgInfoMsg.ServiceFiles = [pkgInfoMsg.ServiceFiles, srvFiles];
                end
                if ~isempty(actFiles)
                    pkgInfoMsg.ActionFiles = [pkgInfoMsg.ActionFiles, actFiles];
                end
            end

            function targetFiles = getFilePathsFromMsgPkgDir(targetFiles, ext)
                fileDir = fullfile(pkgDir,ext);
                folderinfo = dir([fileDir '/*.' ext]);
                if isfolder(fileDir) && numel(folderinfo)
                    for i = 1:numel(folderinfo)
                        targetFiles{end+1} = fullfile(folderinfo(i).folder, folderinfo(i).name); %#ok<AGROW>
                    end
                end
            end

            function filterOutMsgs()
                actionMsgSyntax = {'Action.msg','ActionFeedback.msg','ActionGoal.msg','ActionResult.msg',...
                                   'Feedback.msg','Goal.msg','Result.msg'};
                if ~isempty(actFiles) && ~isempty(msgFiles)
                    for i=1:numel(actFiles)
                        [~,actionName] = fileparts(actFiles{i});
                        for actionMsg = actionMsgSyntax
                            msgFiles(cellfun(@(x)endsWith(x,[actionName actionMsg{1}]),msgFiles)) = [];
                        end
                    end
                end
            end
        end

        function pkgInfo = setPackageInfoFromToolchain(pkgInfo, tcFlags)
        % SETPACKAGEINFOFROMTOOLCHAIN Append the Custom toolchain
        % options set by user through the "Specify" option

            pkgInfo.BuildType = tcFlags.getValue('Build Type').custom.value;
            appendFlagsAsStrings('Defines','CppFlags');
            appendFlagsAsCellArrays('Include Directories','IncludeDirectories');
            appendFlagsAsCellArrays('Link Libraries','Libraries');
            appendFlagsAsCellArrays('Library Paths','LibraryDirectories');
            appendFlagsAsCellArrays('Required Packages','Dependencies');

            function appendFlagsAsStrings(itemName, pkgInfoProp)
                if ~isempty(tcFlags.getValue(itemName).custom.value)
                    orig = pkgInfo.(pkgInfoProp);
                    pkgInfo.(pkgInfoProp) = sprintf("%s %s",[orig, ...
                                                             tcFlags.getValue(itemName).custom.value]);
                end
            end
            function appendFlagsAsCellArrays(itemName, pkgInfoProp)
                if ~isempty(tcFlags.getValue(itemName).custom.value)
                    orig = pkgInfo.(pkgInfoProp);
                    pkgInfo.(pkgInfoProp) = unique([orig, ...
                                                    strip(split(tcFlags.getValue(itemName).custom.value)')]);
                end
            end
        end

        function [ret, missingMsgs, remoteDir] = isCustomMsgsAvail(modelName, requiredCustomMsgs, rosVer, isMATLABCodegen)
        % ISCUSTOMMSGSAVAIL Returns whether custom messages is available on
        % remote device.
            
            ret = true;
            missingMsgs = newline;
            missingMsgPkg = {};
            requiredCustomMsgs = unique(requiredCustomMsgs);

            % Get remote device information
            depObj = ros.codertarget.internal.DeploymentHooks;

            if isMATLABCodegen
                % Get device info from device parameters
                deviceParams = ros.codertarget.internal.DeviceParameters;
                [validHost, validSSH, validUser, validPassword, ~, catkinWs, ~, ...
                    ros2Ws, ~] = deviceParams.getDeviceParameters;
                rosVerOpts = categorical({'ros','ros2'});
                rosVerIdx = (rosVerOpts==rosVer);
                wsFoldersIn = {catkinWs, ros2Ws};
                validRemoteWorkspace = wsFoldersIn{rosVerIdx};
            else
                % Use buildAction as build and load to return a rosTarget since
                % this does not any side effects.
                data = codertarget.data.getData(getActiveConfigSet(modelName));
                buildAction = data.Runtime.BuildAction;
                [validHost, validSSH, validUser, validPassword, validRemoteWorkspace] = ...
                        depObj.verifyConnectionSettings(rosVer, modelName, buildAction);
            end
            % Create ROS/ROS2 connection
            rosTarget = depObj.getConnectionObject(rosVer, validHost, validUser, ...
                validPassword, validSSH, validRemoteWorkspace);

            if strcmp(rosVer,'ros')
                remoteDir = rosTarget.('CatkinWorkspace');
                wksSourceCMD = ['source ' remoteDir '/devel/setup.bash'];
                msgListCMD = 'rosmsg list | grep ';
            else
                remoteDir = rosTarget.('ROS2Workspace');
                wksSourceCMD = ['source ' remoteDir '/install/setup.bash'];
                msgListCMD = 'ros2 interface list | grep ';
            end

            for reqCustomMsg = requiredCustomMsgs
                currentMsg = convertToROSMsgType(reqCustomMsg{1});
                cmd = ['source ' rosTarget.([upper(rosVer) 'Folder']) '/setup.bash && ' ...
                       wksSourceCMD ' && ' ...
                       msgListCMD currentMsg];
                try
                    % This will error out if there is no such message in
                    % target device
                    system(rosTarget,cmd);
                catch
                    ret = false;
                    missingMsgs = [missingMsgs currentMsg newline]; %#ok<AGROW>
                    missingMsgPkg{end+1} = extractBefore(currentMsg,'/'); %#ok<AGROW>
                end
            end
            
            % Add missing messages to ROSSimulinkCgenInfo
            missingMsgPkg = unique(missingMsgPkg);
            if ~isempty(missingMsgPkg)
                cgenInfoSL = ros.codertarget.internal.ROSSimulinkCgenInfo.getInstance;
                cgenInfoSL.addToCustomMsgPkgName(missingMsgPkg);
            end

            function ret = convertToROSMsgType(msg)
                ret = strrep(msg,'::','/');
            end
        end

        function ret = isRemoteBuild(context)
        % ISREMOTEBUILD Returns the value of RemoteBuild field in the
        % context ROS Project data structure. Returns FALSE if the
        % field is not present or value of the field is not a boolean
            if isfield(context, 'ProjectData') && ...
                    isfield(context.ProjectData, 'RemoteBuild')
                ret = context.ProjectData.RemoteBuild;
            else
                ret = false;
            end
        end

        function ret = getROSTimeSteppingMsgDeps(projectData)
            if isfield(projectData,'ROS') && isfield(projectData.ROS,'ROSTimeStepping')...
                    && projectData.ROS.ROSTimeStepping
                ret = {'std_msgs','rosgraph_msgs'};
            else
                ret = {};
            end
        end
        function allMsgInfos = getMsgInfoFromProjectData(projectData, rosVersion)
            allValues = {};
            if isfield(projectData,'Publishers') && (projectData.Publishers.length ~= 0)
                allValues = [allValues projectData.Publishers.values];
            end
            if isfield(projectData,'Subscribers') && (projectData.Subscribers.length ~= 0)
                allValues = [allValues projectData.Subscribers.values];
            end
            allMsgInfos = cellfun(@(x)x.msgInfo,allValues,'UniformOutput',false);
            if isfield(projectData, 'ServiceCallers') && (projectData.ServiceCallers.length ~= 0)
                reqMsgInfo = cellfun(@(x)[x.Request.msgInfo], ...
                                     projectData.ServiceCallers.values,'UniformOutput',false);
                respMsgInfo = cellfun(@(x)[x.Request.msgInfo], ...
                                      projectData.ServiceCallers.values,'UniformOutput',false);
                allMsgInfos = [allMsgInfos reqMsgInfo respMsgInfo];
            end
            if isfield(projectData, 'MessageInfoArray')
                allMsgInfos = [allMsgInfos, projectData.MessageInfoArray];
            end
            if isequal(rosVersion,'ros2') && isfield(projectData, 'MessageTypes')
                for i = 1:numel(projectData.MessageTypes)
                    allMsgInfos = [allMsgInfos ros.internal.ros2.getMessageInfo(projectData.MessageTypes{i,1})]; %#ok<AGROW>
                end
            end
        end
        function [sharedSrcFiles, sharedIncFiles] = getSharedUtilsSources(buildInfo)
        %GETSHAREDUTILSSOURCES Gather shared-utility source files for a
        % input 'buildInfo' argument of a referenced Simulink model
            sharedutilsdir = ros.codertarget.internal.Util.sharedUtilsDir(buildInfo, true);
            if ~isempty(sharedutilsdir)
                % Gather source files
                sharedSrcInfo = dir(fullfile(sharedutilsdir, '*.c*'));
                sharedSrcFiles = fullfile(sharedutilsdir, {sharedSrcInfo.name});
                % Gather header files
                sharedHeaderInfo = dir(fullfile(sharedutilsdir, '*.h'));
                sharedHppHeaderInfo = dir(fullfile(sharedutilsdir, '*.hpp'));
                sharedHeaders = {sharedHeaderInfo.name sharedHppHeaderInfo.name};
                sharedIncFiles = fullfile(sharedutilsdir, sharedHeaders);
            else
                sharedSrcFiles = {};
                sharedIncFiles = {};
            end
        end

        function pkgInfo = setPackageInfoFromContext(pkgInfo, context)
        %SETPACKAGEINFOFROMCONTEXT Set the package information for generation of colcon build
        % project from the Simulink model or MATLAB code-generation project
            if context.isMDL
                % Update package information from the model
                data = codertarget.data.getData(getActiveConfigSet(context.modelName));
                if ~isempty(data) && isfield(data, 'Packaging')
                    % read the packaging details from codertarget data if the hardware board
                    % is set to "Robot Operating System 2 (ROS 2)", else
                    pkgInfo.MaintainerName = data.Packaging.MaintainerName;
                    pkgInfo.MaintainerEmail = data.Packaging.MaintainerEmail;
                    pkgInfo.Version = data.Packaging.Version;
                    pkgInfo.License = data.Packaging.License;
                end
            else
                if isfield(context,'ProjectData')
                    % Ensures build works with Colcon builder with no
                    % MATLAB target selected
                    data = context.ProjectData.PackageInformation;
                    pkgInfo.MaintainerName = data.MaintainerName;
                    pkgInfo.MaintainerEmail = data.MaintainerEmail;
                    pkgInfo.Version = data.Version;
                    pkgInfo.License = data.License;
                end
            end
        end

        function ret = getValidPackageName(val)
        %GETVALIDPACKAGENAME Get a valid package name for a given character
        %vector
            val = convertStringsToChars(val);
            ret = lower(val);
        end

        function ret = convertToUnixPath(val)
        %CONVERTTOUNIXPATH Convert file separator for a given
        %path
            ret = strrep(val,'\','/');
        end
    end

end

% LocalWords:  sharedutils SDK Xgenmsg pkgs dep maci ISREMOTEBUILD GETSHAREDUTILSSOURCES
% LocalWords:  SETPACKAGEINFOFROMCONTEXT GETVALIDPACKAGENAME
