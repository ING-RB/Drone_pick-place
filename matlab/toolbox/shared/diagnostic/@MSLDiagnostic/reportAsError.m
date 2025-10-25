% reportAsError throws MSLException created from MSLDiagnostic
%    
%   reportAsError(DIAG) throws MSLException. By default, if Message Viewer is
%   available it will go to Message Viewer
%    
%   reportAsError(DIAG, MDLNAME) throws MSLException, associated with the model
%   with the name MDLNAME. By default, if Message Viewer is available it 
%   will go to Message Viewer
% 
%   reportAsError(DIAG, MDLNAME, UI) throws MSLException, associated with 
%   the model with the name MDLNAME. If UI = 1 exception will be shown in 
%   Message Viewer (if available), if UI = 0 exception will be shown in MATLAB
%   command line
% 
%   See also MSLException.

%   Copyright 2015-2016 The MathWorks, Inc.
%   Built-in function.
