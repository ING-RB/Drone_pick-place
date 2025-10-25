function installPackageFromPathTool(varargin)
    %

    %   Copyright 2024-2025 The MathWorks, Inc.
    messageStruct = struct('type', 'error', 'details', struct('msg', [], 'id', []));
    try
        mpminstall(varargin{1},"Prompt",false,"Verbosity","Quiet");
        lastError = '';
    catch ME
        lastError = ME;
    end
    if isempty(lastError)
        messageStruct.type = 'success';
        matlab.internal.pathtool_sidepanel.publishToFrontEnd(messageStruct);
    else
        messageStruct.details.msg = lastError.message;
        messageStruct.details.id = lastError.identifier;
        matlab.internal.pathtool_sidepanel.publishToFrontEnd(messageStruct);
    end
end
