function initdesktoputils
%INITDESKTOPUTILS Initialize the MATLAB path and other services for the 
%   desktop and desktop tools. This function is only intended to
%   be called from matlabrc.m and will not have any effect if called after
%   MATLAB is initialized.

%   Copyright 1984-2023 The MathWorks, Inc. 

if usejava('swing') && ~feature('webui')
    com.mathworks.fileutils.MatlabPath.setInitialPath(path);
    
    if ~batchStartupOptionUsed
        %g2374254 - Disable debugger initialization in batch mode
        com.mathworks.mlservices.MatlabDebugServices.initialize;
        com.mathworks.mde.editor.debug.DebuggerInstaller.init();
    end
end
