function [device, errorStruct] = resolveUseGPUForApp(useGPUOption)
%resolveUseGPUForApp Resolve a UseGPU request from the user in an app
%
%   Use matlab.internal.parallel.resolveUseGPUForApp to validate the toggle
%   button "Use GPU" in a toolbox App. This button enables GPU acceleration
%   with Parallel Computing Toolbox.
%
%   [device, errorStruct] =
%   matlab.internal.parallel.resolveUseGPUForApp("on") returns a
%   parallel.gpu.GPUDevice object of the selected GPU device. If a GPU
%   device cannot be selected, then errorStruct contains is a struct with
%   the error message ID and its corresponding text. For backwards
%   compatibility, you can also provide true as the input option to enable
%   the same behavior as "on".
%
%   [device, errorStruct] =
%   matlab.internal.parallel.resolveUseGPUForApp("off") returns an empty
%   0x0 double. For backwards compatibility, you can also provide false as
%   the input option to enable the same behavior as "off".
%
%
% Example of usage:
% function RunButtonPushed(app, event)
%
%   [device, errorStruct] = matlab.internal.parallel.resolveUseGPUForApp(app.UseGPU);
%   if ~isempty(errorStruct)
%       % Create Alert dialog following Parula with the information in
%       % errorStruct: errorID and errorMessage.
%   elseif isempty(device) % empty 0x0 double
%       % Run computation on CPU
%       disp('Run on CPU');
%   else
%       % Run computation on GPU
%       disp('Run on GPU.');
%   end
%
% end
%
%   See also canUseGPU, gpuDevice, validateGPU.

%   Copyright 2024 The MathWorks, Inc.

nargoutchk(2,2);

try
    errorStruct = [];
    useGPUOption = validateLogicalScalarOrOnOff(useGPUOption, ...
        "MATLAB:parallel:gpu:UseGPUInvalidValueForApp");
    device = matlab.internal.parallel.resolveUseGPU(useGPUOption);
catch E
    device = [];
    errorStruct.errorID = E.identifier;
    errorStruct.errorMessage = E.message;
end
end
