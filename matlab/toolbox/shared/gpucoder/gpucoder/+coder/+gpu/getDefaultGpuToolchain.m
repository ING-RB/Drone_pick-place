function selectedTC = getDefaultGpuToolchain(targetLang, isCodingMex)
%getDefaultGpuToolchain : This function selects the appropriate default
% toolchain for GPU coder when none is selected by the user

%   Copyright 2017-2024 The MathWorks, Inc.

    selectedTC = '';

    if ispc
        % On Windows, because NVCC only supports visual studio, we need to
        %  find an appropriate version. First, check mex to see if a valid
        %  version of MSVC is selected
        supportedTCMap = coder.gpu.getSupportedTCMap;
        cc = mex.getCompilerConfigurations(targetLang,'Selected');

        if (~isempty(cc) && isKey(supportedTCMap,cc.ShortName))
            % Check if a supported MSVC toolchain is specified by mex -setup.
            % Assume this is the user's preference, and use the corresponding
            % NVCC toolchain
            selectedTC = supportedTCMap(cc.ShortName);
        elseif (isCodingMex)
            % If no valid toolchain is found and we are coding for MEX, throw
            % an error
            if (~isempty(cc))
                compName = cc.Name;
            else
                compName = 'NONE';
            end
            warning(message('gpucoder:common:NoValidMexGpuCompiler',compName));
        else
            % If mex setup is not supported by GPU Coder, look for all the C++
            % Compilers installed on the host machine and check if MSVC present.
            installedCPPCompilers = {mex.getCompilerConfigurations(targetLang, 'installed').ShortName};
            sortedInstalledCompilers = flip(sort(installedCPPCompilers));
            supportedTCNames = supportedTCMap.keys();
            appearance = dictionary(supportedTCNames, zeros(size(supportedTCNames)));

            for cc = sortedInstalledCompilers
                if isKey(appearance, cc)
                    selectedTC = supportedTCMap(char(cc));
                    break;
                end
            end
            if isempty(selectedTC)
                % No valid toolchain found on the host
                error(message('gpucoder:common:NoValidGpuCoderToolchain'));
            end

        end
    else
        selectedTC = 'NVIDIA CUDA | gmake (64-bit Linux)';
    end

end
