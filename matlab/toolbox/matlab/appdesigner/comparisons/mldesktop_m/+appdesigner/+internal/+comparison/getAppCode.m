function [loadOutcome, codeData, compatibilityData, codeText] = getAppCode(filepath)

    % GETAPPCODE Facade API for App Designer Comparision side getting code
    % data for diff/merge
    %
    % Retrieve the code data and compatiblity data of the App of file - "filepath".  This
    % is called by the Comparison client when the user chooses an App to
    % diff/merge
    
    %
    % Copyright 2021 The MathWorks, Inc.
    
    % Assume load will be successful
    loadOutcome.Status = 'success';
    codeData = struct.empty;

    try
        [codeData, compatibilityData] = appdesigner.internal.comparison.getAppData(filepath);
        if nargout == 4 
            codeText = appdesigner.internal.codegeneration.getAppFileCode(filepath);
        end
    catch me
        % Error Message
        loadOutcome.Message = me.message;
        loadOutcome.Status = 'error';
        loadOutcome.ErrorID = me.identifier;
    end 
end