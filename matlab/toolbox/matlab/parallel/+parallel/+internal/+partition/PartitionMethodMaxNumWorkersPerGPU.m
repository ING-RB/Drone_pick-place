% Implementation for "MaxNumWorkersPerGPU" partitioning of a parallel pool

% Copyright 2024 The MathWorks, Inc.

classdef PartitionMethodMaxNumWorkersPerGPU < parallel.internal.partition.PartitionMethod

    properties (Constant)
        % How long to wait in seconds before issuing a warning about busy
        % workers preventing the partition method
        WarningTimeout = 30;
    end

    methods
        function validateArguments(~, ~, maxNumWorkersPerGPU)
            if ~iIsValidInteger(maxNumWorkersPerGPU)
                throwAsCaller(MException(message("MATLAB:parallel:pool:InvalidPartitionNumWorkersPerGPU")));
            end
        end
        
        function partitionWorkers = partitionWorkers(~, pool, maxNumWorkersPerGPU)
            try
                f = parfevalOnAll(pool, @iGatherGpuDevice, 2);
                ok = wait(f, "finished", parallel.internal.partition.PartitionMethodMaxNumWorkersPerGPU.WarningTimeout);
                if ~ok
                    warningID = "MATLAB:parallel:pool:SlowToGatherGPUDevice";
                    disableWarningCommand = sprintf('warning(''off'', ''%s'')', warningID);
                    parallel.internal.warningNoBackTrace(message('MATLAB:parallel:pool:SlowToGatherGPUDevice', iMakeLink(disableWarningCommand, disableWarningCommand)));
                end
                wait(f, "finished");
                [gpuDeviceInfo, worker] = fetchOutputs(f, "UniformOutput", false);
            catch E
                throwAsCaller(MException(message("MATLAB:parallel:pool:PartitionErrorNumWorkersPerGPU", E.message)));
            end

            noGpu = cellfun(@isempty, gpuDeviceInfo);
            gpuDeviceInfo = gpuDeviceInfo(~noGpu);
            worker = worker(~noGpu);
            gpuDeviceID = cellfun(@(g) g.UUID, gpuDeviceInfo, 'UniformOutput', false);

            allGPUWorkers = [worker{:}];
            [uniqueGPUs, ~, workerGPU] = unique(gpuDeviceID, "stable");
            partitionWorkers = cell(numel(uniqueGPUs), 1);
            for idx = 1:numel(uniqueGPUs)
                workersForGPU = allGPUWorkers(workerGPU == idx);
                numWorkersToSelect = min(numel(workersForGPU), maxNumWorkersPerGPU);
                partitionWorkers{idx} = workersForGPU(1:numWorkersToSelect);
            end
            partitionWorkers = [partitionWorkers{:}];
        end
    end
end


function isValid = iIsValidInteger(n)
isValid = isscalar(n) && ...
        isnumeric(n) && ...
        n >= 0 && ...
        ~isinf(n) && ...
        (round(n) == n);
end

function [gpu, worker] = iGatherGpuDevice()
worker = getCurrentWorker();
try
    gpu = gpuDevice;
catch
    gpu = parallel.gpu.CUDADevice.empty(0,0);
end
end

function link = iMakeLink(cmd, txt)
if matlab.internal.display.isHot
    link = sprintf("<a href=""matlab:%s"">%s</a>", cmd, txt);
else
    link = txt;
end
end