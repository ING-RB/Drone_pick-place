function p = processDialogDataUKF(dlgParams,p)
% processDialogDataUKF Process user data specific to the EKF block
%
% This function processes data from widgets specific to the EKF. Shared
% widgets are handled in processDialogDataEKFUKF() 
%
%   p = processDialogDataUKF(dlgParams, p)
%
%   Inputs:
%     dlgParams - Structure that contains the dialog parameters. This
%                 is created in the 'Mask Initialization' tab of the mask.
%                 It contains all data from all widgets in the block mask.
%     p - A structure. Contains parameters passed onto the blocks under the mask
%
%   Outputs:
%     p - A structure. Contains parameters passed onto the blocks under the mask

%   Copyright 2016 The MathWorks, Inc.

% Validate UKF specific parameters: Alpha, Beta, Kappa
p.Alpha = localValidateAlpha(dlgParams.Alpha, p.DataType);
p.Beta = localValidateBeta(dlgParams.Beta, p.DataType);
p.Kappa = localValidateKappa(dlgParams.Kappa, p.DataType);
end

function alpha = localValidateAlpha(alpha, dataType)
validateattributes(alpha, {'numeric'},...
    {'scalar','real','positive','<=',1},...
    '', ..., % No fcn name
    'Alpha');
alpha = cast(alpha,dataType);
end

function beta = localValidateBeta(beta, dataType)
validateattributes(beta, {'numeric'},...
    {'scalar','real','nonnegative','finite'},...
    '', ..., % No fcn name
    'Beta');
beta = cast(beta, dataType);
end

function kappa = localValidateKappa(kappa, dataType)
validateattributes(kappa, {'numeric'},...
    {'scalar','real','nonnegative','<=',3},...
    '', ..., % No fcn name
    'Kappa');
kappa = cast(kappa, dataType);
end