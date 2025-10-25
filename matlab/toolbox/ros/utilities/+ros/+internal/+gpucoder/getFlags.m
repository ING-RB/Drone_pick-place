function gpuFlags = getFlags(hCS)
% Read additional GPU Compiler flags

gpuFlags = '';

if ros.codertarget.internal.isMATLABConfig(hCS)
    if ~isempty(hCS.GpuConfig)
        if hCS.GpuConfig.Enabled
            customCompute = hCS.GpuConfig.CustomComputeCapability;
            minCompute = hCS.GpuConfig.ComputeCapability;
            gpuCompilerFlags = hCS.GpuConfig.CompilerFlags;

            if ~isempty(customCompute)
                gpuFlags = customCompute;
            else
                ccVals = regexp(minCompute,'\.','split');
                gpuFlags = ['-arch sm_' ccVals{1} ccVals{2}];
            end

            if ~isempty(gpuCompilerFlags)
                gpuFlags = [gpuFlags ' ' gpuCompilerFlags];
            end
        end
    end
else
    if strcmp(get_param(hCS,'GenerateGPUCode'),'CUDA')
        customCompute = get_param(hCS, 'GPUCustomComputeCapability');
        minCompute = get_param(hCS, 'GPUComputeCapability');
        gpuCompilerFlags = get_param(hCS, 'GPUCompilerFlags');

        if ~isempty(customCompute)
            gpuFlags = customCompute;
        else
            ccVals = regexp(minCompute,'\.','split');
            gpuFlags = ['-arch sm_' ccVals{1} ccVals{2}];
        end

        if ~isempty(gpuCompilerFlags)
            gpuFlags = [gpuFlags ' ' gpuCompilerFlags];
        end
    end
end
end