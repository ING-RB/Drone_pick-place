function [status, msgString] = checkCppCompilerForDLAccel()
    % CHECKCPPCOMPILERFORDLACCEL Check for compiler configuration

    %   Copyright 2021 The MathWorks, Inc.

    status = true;
    msgString = "";

    href = '<a href="matlab: mex -setup C++">mex -setup C++</a>';
    compConfig = mex.getCompilerConfigurations('C++','Selected');

    if isempty(compConfig)
        msgString = string(message('gpucoder:system:mex_compiler_not_found', 'NONE', href));
        status = false;
    else
        if ispc
            supportedTCMap = coder.gpu.getSupportedTCMap;
            if ~isKey(supportedTCMap,compConfig.ShortName)
                msgString = string(message('gpucoder:system:mex_compiler_not_found', compConfig.Name, href));
                status = false;
            end
        end
    end

end
