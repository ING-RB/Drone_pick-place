function updateBuildInfo (hCS, buildInfo, remoteBuild)
% Link against the cublas, cufft and cusolver libs when CUDA code
% generation enabled.

%   Copyright 2021-2025 The MathWorks, Inc.

if ros.codertarget.internal.isMATLABConfig(hCS)
    isROS2Workflow = strcmp(hCS.Hardware.Name, 'Robot Operating System 2 (ROS 2)');
    if ~isempty(hCS.GpuConfig)
        if hCS.GpuConfig.Enabled
            if ~isempty(hCS.DeepLearningConfig)
                targetDNN = hCS.DeepLearningConfig.TargetLibrary;
            else
                targetDNN = '';
            end
            updateMLGPUBuildInfo(targetDNN, buildInfo, remoteBuild);
        end
    end
else
    isROS2Workflow = strcmp(hCS.get_param("HardwareBoard"), 'Robot Operating System 2 (ROS 2)');
    if strcmp(get_param(hCS,'GenerateGPUCode'),'CUDA')
        targetDNN = get_param(hCS,'DLTargetLibrary');
        updateMLGPUBuildInfo(targetDNN, buildInfo, remoteBuild);
    end
end

% Update the DL buildinfo for weightfile paths
if remoteBuild
    defToReplace.Name = 'MW_DL_DATA_PATH';
    if isROS2Workflow
        defToReplace.ReplaceWith = 'MW_DL_DATA_PATH=${CMAKE_INSTALL_PREFIX}';
    else
        defToReplace.ReplaceWith = 'MW_DL_DATA_PATH=${CATKIN_DEVEL_PREFIX}';
    end
    loc_reformatDefines(buildInfo, defToReplace);
end

end

function updateMLGPUBuildInfo(taregtDNN, buildInfo, remoteBuild)
if remoteBuild
    if ispc
        buildInfo.removeLinkObjects('cudnn.lib',[],[]);
        buildInfo.removeLinkObjects('nvinfer.lib',[],[]);
    else
        buildInfo.removeLinkObjects('libcudnn.so',[],[]);
        buildInfo.removeLinkObjects('libnvinfer.so',[],[]);
    end
    buildInfo.addLinkFlags('-lcublas');
    buildInfo.addLinkFlags('-lcusolver');
    buildInfo.addLinkFlags('-lcufft');

    if strcmp(taregtDNN,'cudnn')
        buildInfo.addLinkFlags('-lcudnn');
    elseif strcmp(taregtDNN,'tensorrt')
        buildInfo.addLinkFlags('-lcudnn');
        buildInfo.addLinkFlags('-lnvinfer');
    end

    buildInfo.addLinkFlags('-l${CUDA_LIBRARIES}');
else
    if ispc
        pathToCudaLib = fullfile(getenv('CUDA_PATH'),'lib','x64');
        buildInfo.addLinkObjects('cublas.lib', pathToCudaLib, '', true, true);
        buildInfo.addLinkObjects('cufft.lib', pathToCudaLib, '', true, true);
        buildInfo.addLinkObjects('cusolver.lib', pathToCudaLib, '', true, true);

        if strcmp(taregtDNN,'cudnn')
            pathToCuDNNLib = fullfile(getenv('NVIDIA_CUDNN'),'lib','x64');
            buildInfo.addLinkObjects('cudnn.lib', pathToCuDNNLib, '', true, true);
        elseif strcmp(taregtDNN,'tensorrt')
            pathToCuDNNLib = fullfile(getenv('NVIDIA_CUDNN'),'lib','x64');
            buildInfo.addLinkObjects('cudnn.lib', pathToCuDNNLib, '', true, true);

            pathToTensorRTLib = fullfile(getenv('NVIDIA_TENSORRT'),'lib','x64');
            buildInfo.addLinkObjects('nvinfer.lib', pathToTensorRTLib, '', true, true);
        end
    else
        [status, cmdout] = system('which nvcc');
        cmdout = strtrim(cmdout);
        cmdout = replace(cmdout, [filesep filesep], filesep);
        cudaPathRoot = '';
        if status == 0 && ~isempty(cmdout)
            nvccdir = fullfile('bin', 'nvcc');
            pos = strfind(cmdout, nvccdir);
            cudaPathRoot = cmdout(1:pos-2);
        end
        pathToCudaLib = fullfile(cudaPathRoot,'lib64');
        buildInfo.addLinkObjects('libcublas.so', pathToCudaLib, '', true, true);
        buildInfo.addLinkObjects('libcufft.so', pathToCudaLib, '', true, true);
        buildInfo.addLinkObjects('libcusolver.so', pathToCudaLib, '', true, true);

        % In 23b (and 23a, since this change is backported), the
        % cudnn relative lib dir was changed from lib64 to lib.
        % We handle both cases.
        cudnnBase = getenv('NVIDIA_CUDNN');
        if (exist(fullfile(cudnnBase,'lib64','libcudnn.so'), 'file') == 2)
            pathToCuDNNLib = fullfile(cudnnBase, 'lib64');
        else
            pathToCuDNNLib = fullfile(cudnnBase, 'lib');
        end

        % Need to link against libcudnn.so for both cudnn and tensorrt
        % targets.
        buildInfo.addLinkObjects('libcudnn.so', pathToCuDNNLib, '', true, true);
        
        if strcmpi(taregtDNN,'tensorrt')
            tensorrtBase = getenv('NVIDIA_TENSORRT');
            if (exist(fullfile(tensorrtBase,'lib64','libnvinfer.so'), 'file') == 2)
                pathToTensorRTLib = fullfile(tensorrtBase,'lib64');
            else
                pathToTensorRTLib = fullfile(tensorrtBase,'lib');
            end
            buildInfo.addLinkObjects('libnvinfer.so', pathToTensorRTLib, '', true, true);
        end
    end
end
end

%--------------------------------------------------------------------------
function loc_reformatDefines(buildInfo, defToRemove)
    def = buildInfo.getDefines;
    for j = 1:numel(defToRemove)
        for k = 1:numel(def)
            if contains(def{k}, defToRemove(j).Name)
                buildInfo.deleteDefines(def{k});
                buildInfo.addDefines(defToRemove(j).ReplaceWith);
                break;
            end
        end
    end
end