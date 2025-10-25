function validateModalDialogsCapability(options)
% This function is for internal MathWorks use only.

%VALIDATEMODALDIALOGSCAPABILITY Requires ModalDialogs Capability
%   VALIDATEMODALDIALOGSCAPABILITY() will validate that the required
%   Capability.ModalDialogs is available in the execution context. This is
%   intended for dialogs or functions that require user input and block
%   MATLAB execution. The function will additionally error under the
%   NoFigureWindows startup option.
%   VALIDATEMODALDIALOGSCAPABILITY(AllowInNoFigureWindows=true) will allow
%   functions to work under the NoFigureWindows startup option.

%   Copyright 2024 The MathWorks, Inc.
%   Built-in function.

arguments
    options.AllowInNoFigureWindows (1,1) logical = false % Disabled by default    
end

import matlab.internal.capability.Capability;

persistent isdecaf; 
if isempty(isdecaf)
    isdecaf = matlab.ui.internal.dialog.DialogUtils.checkDecaf;
end

% Special handling for web apps.  
% For web apps in JSD, 'modal dialogs' capability is not available. 
% For headless web app servers, the 'NoFigureWindows' feature check returns true, causing unexpected errors, 
% despite in-window dialogs being supported in web apps. (g3460921)
if isdecaf && matlab.ui.internal.dialog.DialogUtils.isDeployedWebAppEnv()
    return
end

if ~isdecaf % Java Desktop
    try
        Capability.require(Capability.Swing);
    catch
        ex = MException(message('MATLAB:hg:NonInteractiveFunctionSupport'));
        throwAsCaller(ex);
    end

elseif ~matlab.ui.internal.utils.BatchModeHelper.isTestToolUsed
    % webui and not in Test Framework
    try
        Capability.require(Capability.ModalDialogs);
    catch
        ex = MException(message('MATLAB:hg:NonInteractiveFunctionSupport'));
        throwAsCaller(ex);
    end
end

% Error in -noFigureWindows if function does not support it. Throw same
% ModalDialogs error. (Capability check does not handle -noFigureWindows)
% For web apps do not error even if feature('NoFigureWindows') is true (check required here only for Java Desktop).
% (g3460921)
if ~matlab.ui.internal.dialog.DialogUtils.isDeployedWebAppEnv() && feature('NoFigureWindows') && ~options.AllowInNoFigureWindows    
    ex = MException(message('MATLAB:hg:NonInteractiveFunctionSupport'));
    throwAsCaller(ex);
end

% Throws error if in -nojvm mode (Java Desktop)
matlab.ui.internal.utils.checkJVMError;
