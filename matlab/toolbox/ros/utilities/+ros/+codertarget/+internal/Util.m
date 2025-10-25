classdef Util
    %This class is for internal use only. It may be removed in the future.

    %codertarget.Util - Utility functions related to generating ROS node
    %                   using Coder Target infrastructure

    %   Copyright 2014-2025 The MathWorks, Inc.

    methods(Static)

        function pkgName = modelNameToValidPackageName(modelName)
            %modelNameToValidPackageName Convert model name to ROS package name
            %   ROS package names should start with a lower case letter and
            %   only contain lower case letters, digits and underscores.

            validateattributes(modelName, {'char'}, {'nonempty'});

            % Make model name lowercase. Then remove all non-word
            % characters (\W regexp), i.e. keep only alphabet characters,
            % underscores & numbers.
            pkgName = regexprep(lower(modelName), '\W', '');
            if isempty(pkgName)
                error(message('ros:slros:cgen:UnableToCreateROSPkgName', modelName));
            end
        end

        function isValid = isValidPackageVersion(versionStr)
            %isValidPackageVersion Verify that ROS package version is valid
            %   Required to be 3 dot-separated integers. See
            %   http://wiki.ros.org/catkin/package.xml.

            % Explicitly make sure that input string is non-empty, since
            % regular expression would match an empty string and falsely
            % return TRUE.
            validateattributes(versionStr, {'char'}, {'nonempty'});
            isValid = strcmpi(versionStr, regexp(versionStr, '^\d+\.\d+\.\d+$', 'match', 'once'));
        end

        function subDirProject = isRefModelSubDirectoryEnabled(modelName)
            % subDirProject Determine if generating code
            % for a referenced model as a sub-directory project is enabled
            subDirProject = false;
            options= {'Standalone',...
                'Sub-directory'};
            % Use this once the 'targets hardware resources' settings are localized
            % options = {message('ros:slros:cgen:ModelRefPkgTypeStandalone').getString,...
            %     message('ros:slros:cgen:ModelRefPkgTypeSubDirectory').getString};
            
            try
                cset = getActiveConfigSet(modelName);
                if codertarget.data.isValidParameter(cset,'ROS.RefMdlPkg')
                    subDirProject = contains(codertarget.data.getParameterValue(cset,'ROS.RefMdlPkg'), options{2});
                end
            catch
                % In case of no target select, we return false directly
                return;
            end
            mdls = find_mdlrefs(modelName,...
                       'KeepModelsLoaded',true, ...
                       'MatchFilter',@Simulink.match.internal.filterOutCodeInactiveVariantSubsystemChoices);
            if (numel(mdls) > 1)
                refMdls = mdls(1:end-1);
                numRefs = numel(refMdls);
                topMdlSetting = repmat(subDirProject,1,numRefs);
                refMdlSettings = false(1,numRefs);
                for k=1:numRefs
                    if codertarget.data.isValidParameter(cset,'ROS.RefMdlPkg')
                        refMdlSettings(k)= contains(codertarget.data.getParameterValue(getActiveConfigSet(refMdls{k}),'ROS.RefMdlPkg'),options{2});
                    end
                end
                diffVal = (topMdlSetting ~= refMdlSettings);
                if any(diffVal)
                    mismatchMdls = refMdls(diffVal);
                    parentSetting = options{subDirProject+1};
                    childSetting = options{~subDirProject+1};
                    excp = MSLException([], message('ros:slros:cgen:RefModelPackageTypeMismatch', ...
                        modelName, mismatchMdls{1},parentSetting,childSetting));
                    throw(excp);
                end
            end
        end

        function ret = isDepthGreaterThanOne(modelName)
        %isDepthGreaterThanOne Determine if model reference depth is greater than 1

            allModels = find_mdlrefs(modelName);
            
            % find_mdlrefs returns all model name included in the opened model.
            % Hence, return false immediately if total number of returned name is
            % less than or equal to 2.
            ret = false;
        
            if numel(allModels)>2
                nestedDepths = cellfun(@(x)numel(find_mdlrefs(x))>1, allModels(1:end-1));
                ret = any(nestedDepths);
            end
        end

        function compProject = isComponentLibProject(modelName)
            % isComponentLibProject Return whether model is configured for ROS 2 component generation

            compProject = false;
            try
                cset = getActiveConfigSet(modelName);
                if codertarget.data.isValidParameter(cset, 'ROS.GenerateROSComponent')
                    compProject = codertarget.data.getParameterValue(cset, 'ROS.GenerateROSComponent');
                end
            catch
                return;
            end
        end

        function pkgInfo = setROSComponentPkgInfo(modelName, pkgInfo, srcFiles, incFiles)
            % setROSComponentPkgInfo Return package information for component generation

            pkgInfo.Dependencies = unique([pkgInfo.Dependencies, ...
                {'rclcpp_components'}]);
            pkgInfo.LibSourceFiles = srcFiles;
            pkgInfo.LibIncludeFiles = incFiles;
            pkgInfo.CppLibraryName = modelName;
            pkgInfo.LibFormat = 'SHARED';
        end

        function isTopLevel = isTopLevelModel(buildInfo)
            %isTopLevelModel Determine if a given model is a top-level or referenced model
            %   ISTOPLEVELMODEL(BUILDINFO) returns TRUE if the model
            %   represented by BUILDINFO is a top-level model.
            %
            %   ISTOPLEVELMODEL(BUILDINFO) returns FALSE if the model is
            %   used as a referenced model

            validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'}, 'isTopLevelModel', 'buildInfo');

            [~, buildArgValue] = findBuildArg(buildInfo, 'MODELREF_TARGET_TYPE');
            isTopLevel = strcmp(buildArgValue, 'NONE');
        end

        function isTopLevel = isExternalModeBuild(buildInfo)
            %isExternalModeBuild Determine if a the build process is generating
            %code for External mode
            %
            %   ISEXTERNALMODEBUILD(BUILDINFO) returns TRUE if the model
            %   represented by BUILDINFO is generating External mode code
            %

            validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'}, 'isTopLevelModel', 'buildInfo');

            [~, buildArgValue] = findBuildArg(buildInfo, 'EXT_MODE');
            isTopLevel = strcmp(buildArgValue, '1');
        end

        function mrefIncFiles = generateModelRefHeaders(buildInfo)
            % GENERATEMODELREFHEADERS Generates <model_ref>.h files and
            % returns the full-file path.
            % 
            % To match the proper 'include' syntax to call the model
            % reference headers, generate a linking file, with same name as
            % the reference model. The file has just one include line
            %    #include "model_ref_pkg_name/ModelRefModelName.h"
            %

            bDir = getSourcePaths(buildInfo,true,{'BuildDir'});
            if isempty(bDir)
                bDir = {pwd};
            end
            modelRefNames = ros.codertarget.internal.Util.uniqueModelRefNames(buildInfo);
            mrefIncFiles = cell(1,numel(modelRefNames));
            for k=1:numel(modelRefNames)
                fName = fullfile(bDir{1},[modelRefNames{k},'.h']);
                pkgName = ros.codertarget.internal.ProjectTool.getValidPackageName(modelRefNames{k});
                fid = fopen(fName,'w');
                fprintf(fid,'#include "%s/%s.h"',pkgName,modelRefNames{k});
                fprintf(fid,'\n');
                fclose(fid);
                mrefIncFiles{k} = fName;
            end
        end

         function [isSingleTasking, sampleTimes, hasExplicitPartitions, baseRateSampleTime] = getSchedulerData(mdlName, buildDir)
            % GETSCHEDULERDATA Determine the scheduling and tasking policy
            % of the Simulink model based on the Solver parameters.
            %
            % isSingleTasking = GETSCHEDULERDATA(mdlName) returns TRUE if
            % the EnableMultiTasking and ConcurrentTasks parameters are
            % false.
            %
            % [isSingleTasking,sampleTimes] = GETSCHEDULERDATA(mdlName)
            % also returns an array sampleTimes containing all the discrete
            % sample times in the Simulink model.
            arguments
                mdlName {mustBeNonzeroLengthText}
                buildDir {mustBeFolder}
            end

            %sch = get_param(mdlName,'Schedule');
            %hasScheduleEditorTasks = ~isempty(sch.RateSections) && ~isempty(sch.Order);
            hasExplicitPartitions = isequal(get_param(mdlName,'ExplicitPartitioning'),'on') ...
                && isequal(get_param(mdlName,'ConcurrentTasks'),'on');
            allSampleTimes = get_param(mdlName,'SampleTimes');
            % Get all discrete sample times, filter out based on the
            % annotation property as it starts with D*
            discrIndx = arrayfun(@(x)startsWith(x.Annotation,'D'),allSampleTimes);
            pSampleTimes = allSampleTimes(discrIndx);

            if hasExplicitPartitions %|| hasScheduleEditorTasks
                % Create sample time structure for periodic tasks
                % specified explicit partitions
                cInfo = load(fullfile(buildDir,"codeInfo.mat"));
                numExplicitTasks = numel(cInfo.codeInfo.OutputFunctions);
                sampleTimes = repmat(struct,numExplicitTasks,1);
                for k=1:numExplicitTasks
                    fcnTiming = cInfo.codeInfo.OutputFunctions(k).Timing;
                    if isequal(fcnTiming.TimingMode,'PERIODIC')
                        sampleTimes(k).Value =[fcnTiming.SamplePeriod fcnTiming.SampleOffset];
                        % For Schedule Editor: first task is a base-rate
                        % step0, rest are sub rates - mark first TID to 0
                        sampleTimes(k).Description = strrep(fcnTiming.NonFcnCallPartitionName, 'D','Discrete ');

                        % Find correct TID from 'SampleTimes' parameter
                        %idx = strcmp({pSampleTimes.Description}, sampleTimes(k).Description);
                        for idx = 1:numel(pSampleTimes)
                            if(isequal(pSampleTimes(idx).Value,sampleTimes(k).Value))
                                break;
                            end
                        end
                        sampleTimes(k).TID = pSampleTimes(idx).TID;
                        % find function name (modelName::StepFun) and
                        % remove modelname:: from there
                        fcnName = cInfo.codeInfo.OutputFunctions(k).Prototype.Name;
                        sampleTimes(k).FcnName = strrep(fcnName,[mdlName '::'],'');
                    else
                        sampleTimes(k) = [];
                    end
                end
            else
                sampleTimes = pSampleTimes;
            end

            %Assign index for each task
            for ii = 1:length(sampleTimes)
                sampleTimes(ii).Idx = ii - 1;
            end

            % Find base rate
            %index = find([pSampleTimes.TID]== 0,1);
            TID_values = [pSampleTimes.TID];
            [~, index] = min(TID_values);
            baseRateSampleTime = pSampleTimes(index).Value(1);
            
            % the model is single tasking if one of the following is true:
            % 1. The 'EnableMultiTasking' setting is 'off' AND
            % 'ConcurrentTasks' is 'off' OR
            % 2. There is only one discrete sample time AND explicit
            % partitions is not enabled
            isSingleTasking = (isequal(get_param(mdlName,'EnableMultiTasking'),'off') || ...
                (numel(sampleTimes) == 1)) && ~hasExplicitPartitions;
        end
        
        function ret = useMemberMethodForRTM(mdlName)
            arguments
                mdlName {mustBeNonzeroLengthText}
            end
            codeDescr = coder.getCodeDescriptor(mdlName);
            mainFileGen = coder.descriptor.internal.MainFileGeneration.findMainFileGeneration(codeDescr.getMF0Model());
            ret = mainFileGen.UseMemberMethodForRTM;
        end

        
        function [modelRefNames, refNodeInfo] = uniqueModelRefNames(buildInfo)
            %uniqueModelRefNames Get names of all model references in model
            %   MODELREFNAMES = uniqueModelRefNames(BUILDINFO) returns the
            %   names of all model references listed in the BUILDINFO for
            %   the current model. The list of MODELREFNAMES will only
            %   contain unique entries.

            validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'}, 'uniqueModelRefNames', 'buildInfo');
            modelRefNames = {};
            refNodeInfo = {};
            if ~isempty(buildInfo.ModelRefs)
                modelRefPaths = arrayfun(@(ref)formatPaths(ref, ref.Path), buildInfo.ModelRefs, 'UniformOutput', false);
                modelRefNames = cell(1,numel(modelRefPaths));
                refNodeInfo = cell(1,numel(modelRefPaths));
                for i = 1:numel(modelRefPaths)
                    thisFullPath = modelRefPaths{i};
                    [~, modelRefNames{i}, ~] = fileparts(thisFullPath);
                    modelInfoFile = fullfile(thisFullPath, 'rosModelInfo.mat');
                    if isfile(modelInfoFile)
                        info = load(modelInfoFile);
                        if isfield(info.rosProjectInfo, 'RefModelNodeInfo')
                            refNodeInfo{i} = info.rosProjectInfo.RefModelNodeInfo;
                        else
                            refNodeInfo{i} = struct('nodeDependencies',{});
                        end
                    end
                end

                % Only find the unique model reference names
                modelRefNames = unique(modelRefNames, 'stable');
            end
        end

        function sharedDir = sharedUtilsDir(buildInfo, isAbsolute)
            %sharedUtilsDir Retrieve relative or absolute path to shared utility sources
            %    SHAREDDIR = sharedUtilsDir(BUILDINFO, false) returns the
            %    path to the shared utility folder relative the current
            %    folder (pwd). If no shared utility folder exists, return
            %    ''.
            %
            %    SHAREDDIR = sharedUtilsDir(BUILDINFO, true) returns the
            %    absolute path to the utility folder.
            sharedDir = '';
            for i = 1:length(buildInfo.BuildArgs)
                if strcmpi(buildInfo.BuildArgs(i).Key, 'SHARED_SRC_DIR')
                    sharedDir = strtrim(buildInfo.BuildArgs(i).Value);
                    break;
                end
            end
            if ~isempty(sharedDir) && isAbsolute
                % Convert relative path to absolute path if needed
                sharedDir = ros.internal.FileSystem.relativeToAbsolute(sharedDir);
            end
        end

        function pkgInfo = addPackageConfigModules(buildInfo,pkgInfo)
            % ADDPKGCONFIGMODULES Parse build-info and add pkg-config modules to
            % PackageInfo
            % The buildInfo link flags that contain
            %
            % Example:
            %   import ros.codertarget.internal.Util
            %   load('packageInfo.mat') % load a pre-generated package info
            %   pkgInfo = Util.addPackageConfigModules(buildInfo,pkgInfo)
            %
            % See also ROS.INTERNAL.PACKAGEINFO



            import ros.codertarget.internal.Util

            validateattributes(buildInfo,{'RTW.BuildInfo'},{'nonempty'});
            validateattributes(pkgInfo,{'ros.internal.PackageInfo'},{'nonempty'});

            pkgCfgModules = Util.getPkgConfigModules(buildInfo);
            if ~isempty(pkgCfgModules)
                cmkPkgCfg = Util.getPkgConfigCMakeOptions(pkgCfgModules);
                pkgInfo.CppFlags = [pkgInfo.CppFlags sprintf('%s ',cmkPkgCfg.cflags)];
                pkgInfo.PkgConfigModules = pkgCfgModules;
                pkgInfo.IncludeDirectories = unique([pkgInfo.IncludeDirectories {cmkPkgCfg.includedirs}]);
                pkgInfo.Libraries = unique([pkgInfo.Libraries {cmkPkgCfg.libraries}]);
                pkgInfo.LibraryDirectories = unique([pkgInfo.LibraryDirectories {cmkPkgCfg.librarydirs}]);
            end
        end

        function cmakeOpts = getPkgConfigCMakeOptions(moduleNames)
            % L_GETPKGCONFIGCMAKEOPTIONS Get CMake options for a cell-array
            % of modules
            %
            % Example:
            %    import ros.codertarget.internal.Util
            %    cmakeOpts = Util.getPkgConfigCMakeOptions({'opencv'});
            %
            %    cmakeOpts =
            %
            %    struct with fields:
            %
            %       pkgsearch: 'pkg_check_modules(OPENCV REQUIRED opencv)'
            %       libraries: '${OPENCV_LIBRARIES}'
            %     includedirs: '${OPENCV_INCLUDE_DIRS}'
            %     librarydirs: '${OPENCV_LIBRARY_DIRS}'
            %          cflags: '${OPENCV_CFLAGS}'

            moduleNames = convertCharsToStrings(moduleNames);
            validateattributes(moduleNames,{'string'},{'row','nonempty'},...
                'getPkgConfigCMakeOptions','moduleNames');
            cmakeOptions = {'pkgsearch','libraries','includedirs','librarydirs','cflags'};
            cmakeOpts = repmat(cell2struct(cell(1,numel(cmakeOptions)),...
                cmakeOptions,2),1,length(moduleNames));

            for k=1:length(moduleNames)
                cmkPkgVar = upper(matlab.lang.makeValidName(moduleNames{k}));
                cmakeOpts(k).pkgsearch = sprintf('pkg_check_modules(%s REQUIRED %s)',...
                    cmkPkgVar,moduleNames{k});
                cmakeOpts(k).cflags  = sprintf('${%s_CFLAGS}',cmkPkgVar);
                cmakeOpts(k).includedirs = sprintf('${%s_INCLUDE_DIRS}',cmkPkgVar);
                cmakeOpts(k).libraries = sprintf('${%s_LIBRARIES}',cmkPkgVar);
                cmakeOpts(k).librarydirs  = sprintf('${%s_LIBRARY_DIRS}',cmkPkgVar);
            end
        end

        function ret = getPkgConfigModules(buildInfo)
            % GETPKGCONFIGMODULES Extract the module names from link and
            % compile flags of buildInfo
            %
            % Example:
            %    import ros.codertarget.internal.Util;
            %    pkgs = Util.getPkgConfigModules(buildInfo);

            validateattributes(buildInfo,{'RTW.BuildInfo'},{'nonempty'},...
                'getPkgConfigModules','buildInfo');
            allLinkFlags = getLinkFlags(buildInfo);
            allCompileOpts = getCompileFlags(buildInfo);
            pkgCfgFlags = [allLinkFlags(contains(allLinkFlags,'pkg-config')), ...
                allCompileOpts(contains(allCompileOpts,'pkg-config'))];
            ret = cell(1,numel(pkgCfgFlags));
            for k=1:numel(pkgCfgFlags)
                % Split "$(XCOMPILERFLAG) `pkg-config --libs --cflags 
                % opencv4`" with spaces. pkg-config uses "--" prefix for any 
                % of its options. For build, --cflags and --libs are 
                % widely used. So, splitting the command with "--" 
                % delimiter to extract the library names. 
                val = regexp(pkgCfgFlags{k},'--\w*','split');
                % Trim the last back-tick character to obtain package name
                ret{k} = strtrim(extractBefore(val{end},'`'));
            end
            ret = unique(ret);
        end

        function [context, linkOnlyObjs, preCompiledObjs] =  addLinkObjects(buildInfo,context)
            % ADDLINKOBJECTS Add link objects to the context structure for use with ROS
            % package information and CMakeLists.txt and package.xml generation
            %
            % Example:
            %   context = struct;
            %   context = ros.codertarget.internal.addLinkObjects(buildInfo,context)


            import ros.codertarget.internal.ProjectTool
            isRemoteBuild = ProjectTool.isRemoteBuild(context);

            validateattributes(buildInfo,{'RTW.BuildInfo'},{'nonempty'});
            validateattributes(context,{'struct'},{'nonempty'});
            allLinkObjs = getLinkObjects(buildInfo);
            isPrecompiled = arrayfun(@(x)x.Precompiled,allLinkObjs);
            isLinkOnly = arrayfun(@(x)x.LinkOnly,allLinkObjs);
            isPrecompiled(isLinkOnly) = false;
            linkOnlyObjs = allLinkObjs(isLinkOnly);
            preCompiledObjs = allLinkObjs(isPrecompiled);

            context = l_addLinkOnlyObjects(linkOnlyObjs,buildInfo,context,isRemoteBuild);

            context = l_addPreCompiledObjects(preCompiledObjs,buildInfo,context);

            context = l_addLinkerFlags(buildInfo,context);

            context = l_addOptionsFromSysLibInfo(buildInfo,context,isRemoteBuild);
        end

        function ret = isROSControlEnabled(modelName)
            % ISROSCONTROLENABLED Returns true if the GenerateROSControl
            % flag of the model is set to true
            %
            % Example:
            %  import ros.codertarget.internal.Util
            %  Util.isROSControlEnabled(modelName)

            try
                ctdata = codertarget.data.getData(getActiveConfigSet(modelName));
                ret = isfield(ctdata,'ROS') && ...
                    isfield(ctdata.ROS,'GenerateROSControl') && ...
                    ctdata.ROS.GenerateROSControl;
            catch ME  
                % Ignore errors in case of no Simulink or Simulink Coder
                ret = false;
            end
            if ret
                % Sanity check to ensure variable generated from ROS
                % Control App are still in model workspace
                mdlWs = get_param(modelName,'ModelWorkspace');
                if ~hasVariable(mdlWs, 'ROSControlClassName_')
                    % Throw warning to open the app and reconfigure for
                    % ROS Control code generation
                    buildStage = sldiagviewer.createStage(message('ros:slros:toolstrip:BuildROSControlActionText').getString, 'ModelName', modelName);
                    stageCleanup = onCleanup(@() delete(buildStage));
                    sldiagviewer.reportWarning(message('ros:slros2:codegen:ROSControlUnconfigured').getString);
                end
            end
        end

        function ret = isROSComponentEnabled(modelName)
            % ISROSCOMPONENTENABLED Returns true if the GenerateROSComponent
            % flag of the model is set to true
            %
            % Example:
            %  import ros.codertarget.internal.Util
            %  Util.isROSComponentEnabled(modelName)

            try
                ctdata = codertarget.data.getData(getActiveConfigSet(modelName));
                ret = isfield(ctdata,'ROS') && ...
                    isfield(ctdata.ROS,'GenerateROSComponent') && ...
                    ctdata.ROS.GenerateROSComponent;
            catch ME  
                % Ignore errors in case of no Simulink or Simulink Coder
                ret = false;
            end
        end
    end
end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function context = l_addLinkOnlyObjects(linkOnlyObjs,buildInfo,context,isRemoteBuild)
cudaSysLibNames = {'cudnn','nvinfer_plugin','nvinfer','cudart','cublas','cufft','cusolver'};
for k = 1:numel(linkOnlyObjs)
    % Ignore rtwshared[.lib,.a] as a custom link object. Compile the
    % shared utility sources as part of the ROS build project.
    isRtwSharedLib = ismember(linkOnlyObjs(k).Name,{'rtwshared','rtwshared.lib','rtwshared.a'});

    % Ignore cuda system libs for remote build. The libraries installed on
    % remote ROS device will be used for linking
    [~,libName,~] = fileparts(linkOnlyObjs(k).Name);
    isCudaSysLib = ismember(libName,cudaSysLibNames);
    if isRtwSharedLib || (isRemoteBuild && isCudaSysLib)
        continue;
    else
        context.ImportedLibs{1,k} = buildInfo.formatPaths(fullfile(linkOnlyObjs(k).Path,linkOnlyObjs(k).Name));
    end
end
end

function context = l_addPreCompiledObjects(preCompObjs,buildInfo,context)
for k = 1:numel(preCompObjs)
    % Ignore rtwshared[.lib,.a] as a custom link object. Compile the
    % shared utility sources as part of the ROS build project.
    if ismember(preCompObjs(k).Name,{'rtwshared','rtwshared.lib','rtwshared.a'})
        continue;
    end
    pathToLib = buildInfo.formatPaths(preCompObjs(k).Path,'replaceStartDirWithRelativePath', true);
    if endsWith(pathToLib,{'.o','.obj','.O','.OBJ'})
        % Include full path for object files
        % Remove special character for space in path
        pathToLib = replace(pathToLib,"\ "," ");
        context.Libraries{end+1} = ['"', replace(pathToLib,'\','/'),'"'];
    else
        context.Libraries{end+1} = preCompObjs(k).Name;
        context.LibraryDirectories{end+1} = fileparts(pathToLib);
    end
end

end


function context = l_addLinkerFlags(buildInfo, context)
    allLinkFlags = strtrim(buildInfo.getLinkFlags);
    % remove linkFlags that have pkg-config
    linkFlags = allLinkFlags(~contains(allLinkFlags,'pkg-config'));
    context.LinkerFlags = {};
    for k = 1:numel(linkFlags)
        if startsWith(linkFlags{k},'-l')
	        % Only process linkFlags starts with '-l'
            tmp = regexp(linkFlags{k}, '-l(\S+)', 'tokens');
            if ~isempty(tmp)
                for j = 1:numel(tmp)
                    context.LinkerFlags  = [context.LinkerFlags, tmp{j}{1}];
                end
            end
        end
    end

    % Read and the custom target libs added by linux target to the linker
    % flags
    targetLibsVarName = 'LINUX_TARGET_CUSTOM_LIBS';
    vars = buildInfo.get("MakeVars");
    for i=1:numel(vars)
        if strcmp(vars(i).Key,targetLibsVarName)
            context.LinkerFlags  = [context.LinkerFlags, vars(i).Value];
            break
        end
    end

end

function context = l_addOptionsFromSysLibInfo(buildInfo,context,isRemoteBuild)
% ADDOPTIONSFROMSYSLIBINFO Adds System library files to package info
%
% SysLib property of buildInfo, contains the system
% libraries shipping with MATLAB root which are supported for
% Linux only. Add these libraries and paths to CMakeLists.txt
%
% EXAMPLE:
%    import ros.codertarget.internal.Util
%    pkgInfo = Util.addOptionsFromSysLibInfo(buildInfo,pkgInfo);

if isRemoteBuild || ~isunix
    return;
end
[libs,libPaths]=getSysLibInfo(buildInfo);
if ~isempty(libPaths)
    libPathsOpts = buildInfo.formatPaths(libPaths);
    context.LibraryDirectories = [context.LibraryDirectories libPathsOpts];
end

if ~isempty(libs)
    context.LinkerFlags = [context.LinkerFlags libs];

    % Remove system stdc++ from the linker flags
    context.LinkerFlags(strcmp(context.LinkerFlags,'stdc++')) = [];
end

if ~ismac
    % In Linux for local code generation, MATLAB shipped version of libstdc++
    % is used by gcc instead of system libstdc++, as system libstdc++ can
    % lead to undefined references to GLIBC_3.4.* during linking time.
    % Maximum Compatible version is GLIBCXX_3.4.28 with MATLAB shipped libstdc++.
    context.LinkerFlags = [{['"' fullfile(matlabroot,'sys/os/glnxa64/orig/libstdc++.so.6') '"']} context.LinkerFlags];
end
end

