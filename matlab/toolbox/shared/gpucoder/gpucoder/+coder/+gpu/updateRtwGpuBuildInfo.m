function updateRtwGpuBuildInfo(buildInfo, buildDir)
%

%   Copyright 2020-2024 The MathWorks, Inc.

    modelInfo = buildInfo.ComponentName;
    customCompute = get_param(modelInfo, 'GPUCustomComputeCapability');
    minCompute = get_param(modelInfo, 'GPUComputeCapability');
    compilerFlags = get_param(modelInfo, 'GPUCompilerFlags');
    if ~isempty(customCompute)
        gpuFlags = customCompute;
        ptxVersion = '350';
    else
        ccVals = regexp(minCompute,'\.','split');
        gpuFlags = ['-arch sm_' ccVals{1} ccVals{2}];
        ptxVersion = [ccVals{1} ccVals{2} '0'];
    end
    if ~isempty(compilerFlags)
        gpuFlags = [gpuFlags ' ' compilerFlags];
    end
    ptxVersion = ['-DMW_CUDA_ARCH=' ptxVersion];

    buildInfo.addCompileFlags(gpuFlags);
    buildInfo.addLinkFlags(gpuFlags);
    buildInfo.addDefines(ptxVersion);

    % Process for memory manager / memory functions
    memoryHeaderDir = fullfile(buildInfo.Settings.Matlabroot, 'toolbox', ...
                               'shared', 'gpucoder', 'src', 'cuda', 'export', 'include', 'cuda');
    memoryHeaderName = 'MWCudaMemoryFunctions.hpp';
    dstFile = fullfile(buildDir, memoryHeaderName);
    copyfile(fullfile(memoryHeaderDir, memoryHeaderName), dstFile, 'f');
    if ispc
        userattrib = '';
    else
        userattrib = 'u';
    end
    fileattrib(dstFile, '+w', userattrib);
    buildInfo.addIncludeFiles(memoryHeaderName);

    memoryManagerEnabled = ...
        strcmp(get_param(modelInfo, 'GPUEnableMemoryManager'), 'on');
    if memoryManagerEnabled
        buildInfo.addDefines('-DMW_GPU_MEMORY_MANAGER');
        safeBuild = get_param(modelInfo, 'GPUErrorChecks');
        if safeBuild
            buildInfo.addDefines('-DMW_GPU_MEMORY_DEBUG');
        end
    end

    addCudaLibs(buildInfo);

end


function addCudaLibs(buildInfo)
    libs = {'cublas', 'cusolver', 'cufft', 'curand', 'cusparse'};

    for i = 1:numel(libs)
        buildInfo.addLinkFlags("-l" + libs{i});
    end
end
