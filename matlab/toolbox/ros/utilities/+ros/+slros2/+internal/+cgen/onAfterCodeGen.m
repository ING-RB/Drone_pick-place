function onAfterCodeGen(hCS, buildInfo)
%This function is for internal use only. It may be removed in the future.

%ONAFTERCODEGEN Hook point for after code generation


%   Copyright 2019-2024 The MathWorks, Inc.

    if ros.codertarget.internal.isMATLABConfig(hCS)
        onAfterCodegenML(hCS,buildInfo);
    else
        onAfterCodegenSL(hCS,buildInfo);
    end
end

function onAfterCodegenSL(hCS, buildInfo)
    import ros.slros2.internal.bus.Util;
    import ros.codertarget.internal.ROS2ControlUtil;

    data = codertarget.data.getData(hCS);
    modelName = buildInfo.ModelName;

    % Get the build directory (that's where we will put the generated files)
    bDir = getSourcePaths(buildInfo, true, {'BuildDir'});
    if isempty(bDir)
        bDir = {pwd};
    end

    isRefModel = ~ros.codertarget.internal.Util.isTopLevelModel(buildInfo);

    % Throw an error if an application with same name as model is already
    % running
    genCodeOnly = strcmp(get_param(modelName,'GenCodeOnly'),'on');
    if ~isRefModel
        loc_errorIfApplicationIsRunning(modelName,genCodeOnly)
    end

    if isRefModel
        % Update buildInfo only for the referenced models
        extList = {'.c' '.C' '.cpp' '.CPP' '.s' '.S'};
        incExtList = {'.h' '.H', '.hpp'};
        updateFilePathsAndExtensions(buildInfo, extList, incExtList);
    end

    extModeInfo = struct.empty();
    if ~isRefModel
        extModeInfo = loc_getExtModeInfo(hCS, buildInfo);
        % Add XCP defines before calling findIncludeFiles
        xcpPlatformDefine = dictionary('win64','-D__WIN32__',...
            'glnxa64','-D__linux__',...
            'maci64','-D__APPLE__ -D__MACH__',...
            'maca64','-D__APPLE__ -D__MACH__');
        if contains(extModeInfo.Protocol,'XCP')
            if ros.codertarget.internal.isRemoteBuild(hCS)
                buildInfo.addDefines(xcpPlatformDefine('glnxa64'));
            else
                buildInfo.addDefines(xcpPlatformDefine(computer('arch')));
            end
        end
    end

    sharedUtilsdir = ros.codertarget.internal.Util.sharedUtilsDir(buildInfo, true);
    if ~isempty(sharedUtilsdir) && isfile(fullfile(sharedUtilsdir, 'buildInfo.mat'))
        % Load the buildInfo.mat file
        sharedBuildInfoData = load(fullfile(sharedUtilsdir, 'buildInfo.mat'), 'buildInfo');
        % Extract the buildInfo from the loaded data
        sharedBuildInfo = sharedBuildInfoData.buildInfo;
        % Copy the src and header files from shared buildInfo to the current buildInfo
        addSourceFiles(buildInfo, sharedBuildInfo.getSourceFiles(true, true));
        addIncludeFiles(buildInfo, sharedBuildInfo.getIncludeFiles(true, true));
    end

    % ignoreParseError converts parsing errors from findIncludeFiles into warnings
    findIncludeFiles(buildInfo, ...
                     'extensions', {'*.h' '*.hpp'}, ...
                     'ignoreParseError', true);

    % Temporary fix for C++ code generation
    removeSourceFiles(buildInfo,...
                      {'ert_main.c', ...
                       'ert_main.cpp', ...
                       'ert_main.cu', ...
                       'rt_cppclass_main.cpp', ...
                       'rt_malloc_main.cpp',... 
                       'linuxinitialize.cpp', ...
                       'main.c'});

    slRefLibrary = 'ros2lib';
    modelParseFcn = @ros.slros2.internal.bus.Util.getROS2BlocksInModel;
    ros2ModelInfo = ros.slros.internal.cgen.getProjectInfo(data, ...
                                                           modelName, isRefModel, ...
                                                           slRefLibrary, modelParseFcn, bDir{1});
    ros2ModelInfo.HasCodeChanged =  ros.codertarget.internal.hasModelChanged;
    
    % Get C++ class interface Settings
    ros2ModelInfo = ros.codertarget.internal.getCppClassDefinition(...
        hCS,bDir{1},ros2ModelInfo);


    % add dependency for ROS 2 Read Image block if exists
    ros2ModelInfo.ImageDepends = {''};
    scriptLoc = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
    imageBlockList = ros.slros.internal.bus.Util.listBlocks(modelName, ...
                                                            ros.slros2.internal.block.ReadImageBlockMask.MaskType);
    if ~isempty(imageBlockList)
        % Only add dependency to OpenCV and include predefined code when
        % processing CompressedImage
        if ismember('sensor_msgs/CompressedImage', ros2ModelInfo.MessageTypes)
            ros2ModelInfo.ImageDepends = {'cv_bridge'};
            % copy the predefined image header file to current directory
            cgenConsts = ros.slros.internal.cgen.Constants;
            buildInfo.addIncludeFiles(cgenConsts.PredefinedCode.ImageHeaderFile);
            copyfile(fullfile(scriptLoc, cgenConsts.PredefinedCode.ImageHeaderFile), ...
                fullfile(bDir{1}, cgenConsts.PredefinedCode.ImageHeaderFile),'f');
        end

        if ismember('sensor_msgs/Image', ros2ModelInfo.MessageTypes)
            % copy the predefined convertToImg header file to current directory
            cgenConsts = ros.slros.internal.cgen.Constants;
            buildInfo.addIncludeFiles(cgenConsts.PredefinedCode.ConvertToImageHeaderFile);
            copyfile(fullfile(scriptLoc, cgenConsts.PredefinedCode.ConvertToImageHeaderFile), ...
                fullfile(bDir{1}, cgenConsts.PredefinedCode.ConvertToImageHeaderFile),'f');
        end

    end

    % Identify service related blocks for help on including predefined
    % service source code.
    ros2ModelInfo.HasSvcBlocks = ~isempty(...
        Util.listBlocks(modelName, ...
                         ['(' ...
                          ros.slros2.internal.block.ServiceCallBlockMask.getMaskType '|' ...
                          ros.slros2.internal.block.ReceiveRequestBlockMask.getMaskType ...
                          ')']));
    % Remove objects created during model updates to avoid repeated servers
    if (ros2ModelInfo.HasSvcBlocks)
        modelWks = get_param(modelName, 'ModelWorkspace');
        evalin(modelWks,"clear('-regexp','ServRec_*')");
    end

    % Identify action related blocks for help on including predefined
    % action source code.
    ros2ModelInfo.HasActBlocks = ~isempty(...
        Util.listBlocks(modelName, ...
                         ['(' ...
                          ros.slros2.internal.block.SendActionGoalBlockMask.getMaskType '|' ...
                          ros.slros2.internal.block.MonitorActionGoalBlockMask.getMaskType '|' ...
                          ros.slros2.internal.block.CancelActionGoalBlockMask.getMaskType ...
                          ')']));

    ros2ModelInfo.HasCurrentTimeBlocks = ~isempty(Util.listBlocks(modelName, ...
        ros.slros2.internal.block.CurrentTimeBlockMask.MaskType));

    ros2ModelInfo.HasGetParamBlocks = ~isempty(Util.listBlocks(modelName, ...
        ros.slros2.internal.block.GetParameterBlockMask.MaskType));

    ros2ModelInfo.HasGetTfBlocks = ~isempty(Util.listBlocks(modelName, ...
        ros.slros2.internal.block.GetTransformBlockMask.MaskType));

    ros2ModelInfo = ros.internal.ros2.augmentModelInfo(ros2ModelInfo);
    % generate conversion and node interface functions only if this is a
    % top-level model

    % Generate the extern definitions for pub/subs for each model in
    % ref-hierarchy
    loc_generateCommonHeaderAndCpp(ros2ModelInfo, buildInfo, bDir);
    
    predefinedCode = ros.slros2.internal.cgen.Constants.ROS2PredefinedCode;
    % Add ParamGetter C++ file to buildInfo
    if (ros2ModelInfo.HasGetParamBlocks)
        addSourceFiles(buildInfo,fullfile(predefinedCode.Location,predefinedCode.CommonParamSource));
    end

    addSourceFiles(buildInfo,fullfile(predefinedCode.Location,predefinedCode.SlROS2ExecutorSource));

    % Add Transform C++ file to buildInfo
    if (ros2ModelInfo.HasGetTfBlocks)
        addIncludeFiles(buildInfo, fullfile(predefinedCode.Location, predefinedCode.CommonTransformHeader));
    end
    
    % set remote build property
    if isfield(data.ROS, 'RemoteBuild') && islogical(data.ROS.RemoteBuild)
        ros2ModelInfo.RemoteBuild = data.ROS.RemoteBuild;
    end

    % Set <modelname>_types.h
    existingIncludeFiles = buildInfo.getIncludeFiles(true, true);
    modelTypesHdrIdx = find(contains(existingIncludeFiles, [modelName '_types.']));
    if ~isempty(modelTypesHdrIdx)
        [~, fname, ext] = fileparts( existingIncludeFiles{modelTypesHdrIdx} );
        ros2ModelInfo.ModelTypesHeader = [fname ext];
    else
        ros2ModelInfo.ModelTypesHeader = '';
    end
    % Generate MSG-to-BUS and BUS-to-MSG conversion functions
    % generate node interface functions only if this is a top-level model
    loc_generateConversionFcns(ros2ModelInfo, modelName, buildInfo, bDir{1});
    if ~isRefModel
        % Add External mode information
        extModeInfo.ExtmodeSim = ros.codertarget.internal.Util.isExternalModeBuild(buildInfo);
        if extModeInfo.ExtmodeSim
            % get values from the ExtMode configset
            extModeInfo.Port = codertarget.attributes.getExtModeData('Port', hCS);
            extModeInfo.RunInBackground = codertarget.attributes.getExtModeData('RunInBackground', hCS);
            extModeInfo.Verbose = codertarget.attributes.getExtModeData('Verbose', hCS);
        else
            % set default values
            extModeInfo.Port = '17725';
            extModeInfo.RunInBackground = true;
            extModeInfo.Verbose = '0';
        end
        ros2ModelInfo.ExtmodeInfo = extModeInfo;

        if ros.codertarget.internal.Util.isROSControlEnabled(modelName)
            % Template generation for ROS 2 Control package
            ROS2ControlUtil.generateROSControlFiles(ros2ModelInfo, bDir{1}, buildInfo);
        else
            if ros.codertarget.internal.Util.isComponentLibProject(modelName)
                % Add define for component generation
                % No additional templates required compared with standard
                % node generation
                buildInfo.addDefines('_SL_ROS2_COMPONENT_');
            end
            % Template generation for ros2matlabnodeinterface.h/cpp
            loc_generateNodeInterface(ros2ModelInfo, buildInfo, bDir{1});
        end
    end

    % Link against the cublas, cufft and cusolver libs when CUDA code
    % generation enabled.
    ros.internal.gpucoder.updateBuildInfo(hCS, buildInfo, ros2ModelInfo.RemoteBuild);
    ros2ModelInfo.GPUFlags = ros.internal.gpucoder.getFlags(hCS);


    %save ros2modelinfo
    save(fullfile(bDir{1}, ros.slros2.internal.cgen.Constants.ROS2ModelInfoFile), ...
         'ros2ModelInfo');

    % Replace the define '-DRT' with '-DRT=RT'. This define clashes with a
    % definition in BOOST math library
    defToReplace.Name = 'RT';
    defToReplace.ReplaceWith = 'RT=RT';

    % For Remote Device (Linux) deployment, replace host-specific UDP block
    % files (linking with MATLAB host library, libmwnetwordevice.dll/so)
    % with target-specific ones (linuxUDP.c)
    if ros2ModelInfo.RemoteBuild
        loc_replaceDefines(buildInfo, defToReplace);
        fileToFind = fullfile('$(MATLAB_ROOT)','toolbox','shared','spc','src_ml','extern','src','DAHostLib_Network.c');
        found = loc_findInBuildInfoSrc(buildInfo,fileToFind);
        if ~isempty(found)
            sourceFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
            loc_addUDPBlocksToBuildInfo(buildInfo, sourceFolder);
        end
    end

    sDir = getSourcePaths(buildInfo, true, {'StartDir'});
    if isempty(sDir)
        sDir = {pwd};
    end
    % Copy build_ros2_model.sh to the same directory as the archive file
    scriptName = 'build_ros2_model.sh';
    targetScript = fullfile(sDir{1}, scriptName);
    copyfile(fullfile(scriptLoc, scriptName), targetScript, 'f');
end

function onAfterCodegenML(hCS, buildInfo)
% Convert MATLAB target parameters to the format used for Simulink
    bDir = ros.codertarget.internal.getBuildDir(buildInfo);
    [~,modelName] = findBuildArg(buildInfo,'MLC_TARGET_NAME');
    % For stand-alone executable build, entry point function cannot take
    % input arguments or return outputs
    numInputs = nargin(modelName);
    numOutputs = nargout(modelName);
    coder.internal.setBuildInfoTargetWordSizes(buildInfo, hCS);
    if strcmpi(hCS.OutputType,'exe') && ((numInputs > 0) || (numOutputs > 0))
        error(message('ros:utilities:util:InvalidFunctionPrototype',...
                      modelName,numInputs,numOutputs));
    end
    ros2ModelInfo = loc_mlGetProjectInfo(hCS, modelName);
    isRemoteBuild = ~isequal(hCS.Hardware.DeployTo,'Localhost');
    ros2ModelInfo.RemoteBuild = isRemoteBuild;

    % Only generate code if GenCodeOnly is true or BuildAction been set
    % to None. When BuildAction is 'None', we need to set GenCodeOnly
    % to true since there are hook points later on to check this
    % variable.
    if strcmp(hCS.Hardware.BuildAction,'None')
        hCS.GenCodeOnly = true;
    end
    genCodeOnly = hCS.GenCodeOnly;
    buildInfo.addBuildArgs('GEN_CODE_ONLY',{num2str(genCodeOnly)});

    if ~isRemoteBuild && ~genCodeOnly
        loc_errorIfApplicationIsRunning(modelName, genCodeOnly);
    end

    cgenInfo = ros.codertarget.internal.ROSMATLABCgenInfo.getInstance;
    if numel(getNodes(cgenInfo)) > 1
        assert(false, message('ros:mlros2:codegen:MultipleNodesNotAllowed',modelName));
    end
    if ~isempty(getMessageTypesWithInt64(cgenInfo)) && ~hCS.HardwareImplementation.ProdLongLongMode
        warning(message('ros:mlroscpp:codegen:SetProdLongLongMode',modelName));
    end

    if ~isempty(getNodes(cgenInfo))
        [baseName, namespace] = getNodeNameParts(cgenInfo, cgenInfo.NodeList{1});
        ros2ModelInfo.Namespace = namespace;
        ros2ModelInfo.NodeName = baseName;
    else
        ros2ModelInfo.Namespace = '';
        ros2ModelInfo.NodeName = modelName;
    end

    setNodeName(cgenInfo,ros2ModelInfo.NodeName);
    nodeinfo = getNodeDependencies(cgenInfo);

    uniqueMsgList = unique(nodeinfo.messageList);
    % Write message information to the project info for use with
    % ProjectTool and local deployment
    ros2ModelInfo.MessageInfoArray = cell(1,numel(uniqueMsgList));
    for k=1:numel(uniqueMsgList)
        [~,~,msgInfo] = ros.internal.getEmptyMessage(uniqueMsgList{k},'ros2');
        ros2ModelInfo.MessageInfoArray{k} = msgInfo;
    end

    % Write node parameter information to the project info
    if ~isempty(cgenInfo.NodeParameters(1).Value)
        ros2ModelInfo.ParameterList = cgenInfo.NodeParameters;
    else
        ros2ModelInfo.ParameterList = {};
    end

    % Generate main.cpp
    mainFile = fullfile(bDir,'main.cpp');
    mainTempl = fullfile(toolboxdir('ros'),'codertarget','templates','ros2_ml_main.cpp.tmpl');
    % generate node interface header
    loc_createOutput(ros2ModelInfo, mainTempl, mainFile);
    addSourceFiles(buildInfo,mainFile);

    % Generate message conversion functions, struct type definitions, etc.
    serviceTypes = {};
    if ~isempty(cgenInfo.getMessageTypes)
        typesHeader = [modelName,'_types.h'];
        conversionFiles = ros.slros.internal.cgen.generateAllConversionFcns(...
            cgenInfo.getMessageTypes, serviceTypes, hCS, typesHeader, bDir, ...
            'BusUtilityObject',ros.slros2.internal.bus.Util, ...
            'CodeGenUtilityObject',ros.slros2.internal.cgen.Util,...
            'ROSHeader','"rclcpp/rclcpp.hpp"');
        addIncludeFiles(buildInfo, fullfile(bDir,conversionFiles.HeaderFiles));
        addSourceFiles(buildInfo,  fullfile(bDir,conversionFiles.SourceFiles));
        msgConvertData.HasCoderArray = contains(fileread(fullfile(bDir,typesHeader)),'coder_array.h');
        msgConvertData.NodeName = modelName;
        msgConvertData.ROSVer = 'ros2';
        tmpl = ros.internal.emitter.MLTemplate;
        tmpl.loadFile(fullfile(toolboxdir('ros'),'codertarget','templates','mlroscpp_msgconvert_utils.h.tmpl'));
        tmpl.outFile = fullfile(bDir, 'mlros2_msgconvert_utils.h');
        tmpl.render(msgConvertData,2);
        addIncludeFiles(buildInfo, tmpl.outFile);
    end
    ros2ModelInfo.AddRTWTypesHeader = isfile(fullfile(bDir,'rtwtypes.h'));
    % Set image block dependency field to empty here to avoid conflict
    ros2ModelInfo.ImageDepends = {''};

    % Link against the cublas, cufft and cusolver libs when CUDA code
    % generation enabled.
    ros.internal.gpucoder.updateBuildInfo(hCS, buildInfo, ros2ModelInfo.RemoteBuild);
    ros2ModelInfo.GPUFlags = ros.internal.gpucoder.getFlags(hCS); 

    %save ros2modelinfo
    save(fullfile(bDir, 'ros2ModelInfo.mat'), 'ros2ModelInfo');

    % Replace the define '-DRT' with '-DRT=RT'. This define clashes with a
    % definition in BOOST math library
    defToReplace.Name = 'RT';
    defToReplace.ReplaceWith = 'RT=RT';
    loc_replaceDefines(buildInfo, defToReplace);
    sDir = getSourcePaths(buildInfo, true, {'StartDir'});
    if isempty(sDir)
        sDir = {pwd};
    end
    % Copy build_model.sh to the same directory as the archive file
    scriptName = 'build_ros2_model.sh';
    targetScript = fullfile(sDir{1}, scriptName);
    scriptLoc = ros.slros.internal.cgen.Constants.PredefinedCode.Location;

    if  any(contains(buildInfo.getSourceFiles(true,true), 'rosReadImage.cpp'))
        % copy the predefined convertToImg header file to current directory
        cgenConsts = ros.slros.internal.cgen.Constants;
        buildInfo.addIncludeFiles(cgenConsts.PredefinedCode.ConvertToImageHeaderFile);
        copyfile(fullfile(scriptLoc, cgenConsts.PredefinedCode.ConvertToImageHeaderFile), ...
            fullfile(bDir, cgenConsts.PredefinedCode.ConvertToImageHeaderFile),'f');
    end
    copyfile(fullfile(scriptLoc, scriptName), targetScript, 'f');

end



%--------------------------------------------------------------------------
% Internal functions
%--------------------------------------------------------------------------

function loc_generateCommonHeaderAndCpp(ros2ModelInfo, buildInfo, bDir)
    ros2NodeConsts = ros.slros2.internal.cgen.Constants.NodeInterface;
    % generate common header
    loc_createOutput(ros2ModelInfo, ros2NodeConsts.CommonHeaderTemplate, ...
                     fullfile(bDir{1}, ros2NodeConsts.CommonHeader));
    addIncludeFiles(buildInfo,fullfile(bDir{1},ros2NodeConsts.CommonHeader));

    % generate common cpp
    loc_createOutput(ros2ModelInfo, ros2NodeConsts.CommonCppTmpl, ...
                     fullfile(bDir{1}, ros2NodeConsts.CommonCpp));
    addSourceFiles(buildInfo,fullfile(bDir{1},ros2NodeConsts.CommonCpp));
end

%--------------------------------------------------------------------------
function loc_generateNodeInterface(ros2ModelInfo, buildInfo, bDir)
    ros2NodeConsts = ros.slros2.internal.cgen.Constants.NodeInterface;
    if isequal(get_param(ros2ModelInfo.ModelName,'CodeInterfacePackaging'),'C++ class')
        % when C++ class is selected for packaging - template is different
        headerTempl = ros2NodeConsts.HeaderTemplate;
        sourceTempl = ros2NodeConsts.SourceFileTemplate;
        % when generating C++ class from model that has MDS feature
        % on, copy step function definition from rt_main.cpp (g3241561).
        if ros2ModelInfo.HasExplicitPartitions
            ros2ModelInfo.PartitionStepDefinition = fileread('rt_main.cpp');
        end
    else
        headerTempl = ros2NodeConsts.NonresuableFcnHeaderTemplate;
        sourceTempl = ros2NodeConsts.NonresuableFcnSourceFileTemplate;
    end
    % generate node interface header
    loc_createOutput(ros2ModelInfo, headerTempl, ...
                     fullfile(bDir, ros2NodeConsts.HeaderFile));
    % generate node interface CPP
    loc_createOutput(ros2ModelInfo, sourceTempl, ...
                     fullfile(bDir, ros2NodeConsts.SourceFile));

    if ~ros.codertarget.internal.Util.isComponentLibProject(ros2ModelInfo.ModelName) ...
            && ~ros.codertarget.internal.Util.isROSControlEnabled(ros2ModelInfo.ModelName)
        % generate ROS2 Main CPP
        loc_createOutput(ros2ModelInfo, ros2NodeConsts.MainTemplate, ...
                         fullfile(bDir, ros2NodeConsts.MainFile));
        buildInfo.addSourceFiles(ros2NodeConsts.MainFile);
    end
    % Add node related build artifacts to buildInfo. Add only the
    % names of the header and CPP file as the buildInfo already has the
    % SourcePaths/IncludePaths for code-generation folder and will look for
    % those headers and includes
    buildInfo.addIncludeFiles(fullfile(bDir,ros2NodeConsts.HeaderFile));
    buildInfo.addSourceFiles(ros2NodeConsts.SourceFile);
end

%--------------------------------------------------------------------------
function loc_generateConversionFcns(ros2ModelInfo, modelName, buildInfo, bDir)

% Find a header file that looks like <modelname>_types.h. This contains
% definitions of the bus structs, and needs to be included by the bus
% conversion header
    predefinedCode = ros.slros2.internal.cgen.Constants.ROS2PredefinedCode;
    % Generate all the conversion functions
    conversionFiles = ros.slros.internal.cgen.generateAllConversionFcns(...
        ros2ModelInfo.MessageTypes, {}, modelName, ros2ModelInfo.ModelTypesHeader, bDir, ...
        'BusUtilityObject', ros.slros2.internal.bus.Util, ...
        'CodeGenUtilityObject', ros.slros2.internal.cgen.Util, ...
        'ROSHeader', '"rclcpp/rclcpp.hpp"');
    addIncludeFiles(buildInfo,  fullfile(bDir,conversionFiles.SourceFiles));
    % Add slros_msgconvert_utils.h
    buildInfo.addIncludePaths(predefinedCode.Location);
    addIncludeFiles(buildInfo,fullfile(predefinedCode.Location,...
                                       predefinedCode.ConversionUtilsHeaderFile));

    % Add SlROS2 executor related header
    addIncludeFiles(buildInfo,fullfile(predefinedCode.Location,...
                                       predefinedCode.SlROS2ExecutorHeader));

    % Add pub-sub header
    addIncludeFiles(buildInfo,fullfile(predefinedCode.Location,...
                                       predefinedCode.CommonPubSubHeader));

    if (ros2ModelInfo.HasSvcBlocks)
        % Add common service header
        addIncludeFiles(buildInfo,fullfile(predefinedCode.Location,...
                                           predefinedCode.CommonServiceHeader));
    end
    
    if (ros2ModelInfo.HasActBlocks)
        % Add common action header
        addIncludeFiles(buildInfo,fullfile(predefinedCode.Location,...
                                           predefinedCode.CommonActionHeader));
    end
end

function loc_errorIfApplicationIsRunning(exeName, isGenCodeOnly)
% LOC_ERRORIFAPPLICATIONISRUNNING Throw an error if the application with same name
% as model is running already. If the model is set to GenerateCode only, no need to
% error out since compilation will not happen and only the C++/Header files and
% makefiles will be generated.

    if ~isGenCodeOnly
        % Create a map of name of applications per platform
        appNameMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                                    {[exeName, '.exe'], exeName, exeName, exeName});
        % Create a map of system commands that will query for running application
        isAppRunningCmdMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                                            {sprintf('wmic process where "name=''%s''" get ProcessID,ExecutablePath', appNameMap('win64')), ... use wmic query
                                             sprintf('ps ax | grep "%s" | grep -v "grep"', appNameMap('maci64')), ...  use pidof
                                             sprintf('ps ax | grep "%s" | grep -v "grep"', appNameMap('maca64')), ...  use pidof
                                             sprintf('ps ax | grep "%s" | grep -v "grep"', appNameMap('glnxa64')) ...  use pidof
                                            });
        % Get the correct command
        cmd = isAppRunningCmdMap(computer('arch'));
        [status, result] = system(cmd);
        isRunning = false;
        % if status is non-zero, assume application was not running
        if isequal(status, 0)
            isRunning = contains(strtrim(result), appNameMap(computer('arch')));
        end
        if isRunning
            disp(result); % diagnostic
            throwAsCaller(MSLException([], message('ros:slros2:codegen:NodeAlreadyRunningError', exeName, appNameMap(computer('arch')))));
        end
    end
end

%--------------------------------------------------------------------------
function loc_replaceDefines(buildInfo, defToRemove)
    def = buildInfo.getDefines;
    for j = 1:numel(defToRemove)
        for k = 1:numel(def)
            if isequal(def{k}, ['-D', defToRemove(j).Name])
                buildInfo.deleteDefines(defToRemove(j).Name);
                buildInfo.addDefines(defToRemove(j).ReplaceWith);
                break;
            end
        end
    end
end

%--------------------------------------------------------------------------
function loc_createOutput(data,tmplFile,outFile)
%Load the given template and render the data in it.

    tmpl = ros.internal.emitter.MLTemplate;
    tmpl.loadFile(tmplFile);
    tmpl.outFile = outFile;
    tmpl.render(data, 2);
end

%--------------------------------------------------------------------------
function extModeInfo = loc_getExtModeInfo(hCS,buildInfo)
% GETEXTMODEINFO Populate ExtmodeInfo structure
extModeInfo.ExtmodeSim = ros.codertarget.internal.Util.isExternalModeBuild(buildInfo);
if extModeInfo.ExtmodeSim
    % get values from the ExtMode configset
    extModeInfo.Port = codertarget.attributes.getExtModeData('Port', hCS);
    extModeInfo.RunInBackground = codertarget.attributes.getExtModeData('RunInBackground', hCS);
    extModeInfo.Verbose = codertarget.attributes.getExtModeData('Verbose', hCS);
    extModeInfo.Protocol = codertarget.attributes.getExtModeData('Transport',hCS);
else
    % set default values
    extModeInfo.Port = '17725';
    extModeInfo.RunInBackground = true;
    extModeInfo.Verbose = '0';
    extModeInfo.Protocol = 'TCP/IP';
end
end

%--------------------------------------------------------------------------
function rosProjectInfo = loc_mlGetProjectInfo(hCS, modelName)
% MATLAB ROS 2 project generation meta data

% Store Package information
    rosProjectInfo = struct;
    rosProjectInfo.ModelName = modelName;
    % Generate a structure that ROS project builder expects to see. The
    % structure contains package information
    rosProjectInfo.PackageInformation = struct(...
        'MaintainerName',hCS.Hardware.PackageMaintainerName,...
        'MaintainerEmail',hCS.Hardware.PackageMaintainerEmail,...
        'License',hCS.Hardware.PackageLicense,...
        'Version',hCS.Hardware.PackageVersion);
    rosProjectInfo.ROS = struct(...
        'ROS2Folder',hCS.Hardware.ROS2Folder,...
        'ROS2Workspace',hCS.Hardware.ROS2Workspace,...
        'RemoteBuild',~isequal(hCS.Hardware.DeployTo,'Localhost'));

    % Set build arguments needed for remote build
    rosProjectInfo.RemoteBuild = rosProjectInfo.ROS.RemoteBuild;
    rosProjectInfo.BuildArguments = [];
    rosProjectInfo.StepMethodName = [];
    rosProjectInfo.ModelClassName = [];
end


%--------------------------------------------------------------------------
function loc_addUDPBlocksToBuildInfo(buildInfo, sourceFolder)
    filePathToAdd = sourceFolder;
    fileNameToAdd = 'linuxUDP.c';

    addSourceFiles(buildInfo,fileNameToAdd,filePathToAdd);
    addDefines(buildInfo,'_USE_TARGET_UDP_');
end

%--------------------------------------------------------------------------
function found = loc_findInBuildInfoSrc(buildInfo,filename)
    filename = strrep(filename,'$(MATLAB_ROOT)',matlabroot);
    found = [];
    for j=1:length(buildInfo.Src.Files)
        iFile = fullfile(buildInfo.Src.Files(j).Path, buildInfo.Src.Files(j).FileName);
        iFile = strrep(iFile,'$(MATLAB_ROOT)',matlabroot);
        if contains(iFile, filename)
            found = iFile;
            break;
        end
    end
end
