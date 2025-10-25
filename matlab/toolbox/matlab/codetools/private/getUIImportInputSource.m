function [useFileDialog, useClipboard] = getUIImportInputSource()
    % This class is unsupported and might change or be removed without notice in a
    % future version.
        
    % Copyright 2020-2023 The MathWorks, Inc.
    import matlab.internal.capability.Capability;
    useFileDialog = false;
    useClipboard = false;
    
    if Capability.isSupported(Capability.LocalClient)
        % Supports file and clipboard, so show a dialog to let the user choose
        fileStr = getString(message('MATLAB:codetools:uiimport:File'));
        clipStr = getString(message('MATLAB:codetools:uiimport:Clipboard'));
        cancelStr = getString(message('MATLAB:codetools:uiimport:Cancel'));
        requestedAction = questdlg(getString(message('MATLAB:codetools:uiimport:SelectADataInputSource')), ...
            getString(message('MATLAB:codetools:uiimport:SelectSource')),...
            fileStr, clipStr, cancelStr, fileStr);
        switch(requestedAction)
            case fileStr
                useFileDialog = true;
            case clipStr
                useClipboard = true;
        end
    else
        useFileDialog = true;
    end
end
