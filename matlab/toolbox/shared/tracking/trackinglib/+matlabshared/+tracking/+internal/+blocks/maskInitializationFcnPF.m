function [p,signalCheck] = maskInitializationFcnPF(blkH,dlgParams)
% maskInitializationFcnPF Mask initialization function for the FF block
%
%   p = maskInitializationFcn(blkH,dlgParams)
%
%   Inputs:
%     blkH      - Handle to the block
%     dlgParams - Structure that contains the dialog parameters. This
%                 structure is created in the 'Mask Initialization' tab
%                 of the block mask.
%
%   Outputs:
%     p           - Structure with parameters passed onto the blocks under the mask
%     signalCheck - Structure with parameters for signal check S-Fcns

%   Copyright 2016-2017 The MathWorks, Inc.

% Gather info about functions
dlgParams.FcnInfo = ...
    matlabshared.tracking.internal.blocks.getFunctionInfo(...
    'PF', blkH, dlgParams.FcnInfo);

% Set the IO ports provided to the user based on the dialog settings
matlabshared.tracking.internal.blocks.configureBlockPF(blkH, 'PF', dlgParams);

% Error checking: Skip the error checking if this function is triggered by
% the user clicking the 'OK' or 'Apply' buttons on the dialog
if strcmp(get_param(bdroot,'SimulationStatus'),'stopped')
    % User just interacted with the dialog. Skip error checking
    p = [];
    signalCheck = [];
else
    % Process user data and report errors back to the users
    [p,signalCheck] = matlabshared.tracking.internal.blocks.processDialogDataPF(blkH,dlgParams);
end
end