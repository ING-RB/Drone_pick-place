function p = processDialogDataEKF(dlgParams, p)
% processDialogDataEKF Process user data specific to the EKF block
%
% This function processes data from widgets specific to the EKF. Shared
% widgets are handled in processDialogDataEKFUKF() 
%
%   p = processDialogData(dlgParams,p)
%
%   Inputs:
%     dlgParams - Structure that contains the dialog parameters. This
%                 is created in the 'Mask Initialization' tab of the mask.
%                 It contains all data from all widgets in the block mask.
%     p - A structure. Contains parameters passed onto the blocks under the mask
%
%   Outputs:
%     p - A structure. Contains parameters passed onto the blocks under the mask

%   Copyright 2016-2017 The MathWorks, Inc.

%% EKF Specific code: Jacobians
p.HasJacobian = localProcessHasJacobian(dlgParams);
[p.StateTransitionJacobianFcn, p.MeasurementJacobianFcn] = localProcessJacobianFcnNames(dlgParams);
end

function J = localProcessHasJacobian(dlgParams)
J.StateTransitionFcn = dlgParams.FcnInfo.Predict.HasJacobian;
J.MeasurementFcn = dlgParams.FcnInfo.Correct.HasJacobian;
end

function [STJFcn, MJFcn] = localProcessJacobianFcnNames(dlgParams)

S = dlgParams.FcnInfo.Predict;
localLocalValidateFcn(S.Fcn{1}, S.JacobianFcn{1}, ...
    S.FcnType{1}, S.JacobianFcnType{1}, ...
    S.FcnNargin(1), S.JacobianFcnNargin(1),...
    S.JacobianFcnNargout(1), S.JacobianFcnErrors{1},...
    S.HasJacobian(1),...
    S.HasAdditiveNoise(1));
STJFcn.Name = S.JacobianFcn{1};

S = dlgParams.FcnInfo.Correct;
MJFcn.FcnName = cell(dlgParams.NumberOfMeasurements,1);
for kk=1:dlgParams.NumberOfMeasurements
    localLocalValidateFcn(S.Fcn{kk}, S.JacobianFcn{kk}, ...
        S.FcnType{kk}, S.JacobianFcnType{kk}, ...
        S.FcnNargin(kk), S.JacobianFcnNargin(kk),...
        S.JacobianFcnNargout(kk), S.JacobianFcnErrors{kk},...
        S.HasJacobian(kk),...
        S.HasAdditiveNoise(kk));
    MJFcn.Name{kk} = S.JacobianFcn{kk};
end


    function localLocalValidateFcn(fcnName, jacobianFcnName, ...
            fcnType, jacobianFcnType, fcnNargin, jacobianFcnNargin, ...
            jacobianFcnNargout, jacobianFcnErrors, ...
            hasJacobian, hasAdditiveNoise)
        % If user did not provide Jacobian, there is nothing to check
        if ~hasJacobian
            return;
        end
        % Throw errors that were caught during function processing
        if ~isempty(jacobianFcnErrors)
            error(jacobianFcnErrors)
        end
        % The type of the Fcn and JacobianFcn must match
        if ~strcmp(fcnType,jacobianFcnType)
            error(message('shared_tracking:blocks:errorJacobianFcnTypeMismatch',fcnName,jacobianFcnName));
        end
        % Nargin must match for Fcn and its Jacobian. In case of varargin,
        % we may find -1. Skip the check in that case.
        if fcnNargin~=-1 && jacobianFcnNargin~=-1 && fcnNargin~=jacobianFcnNargin
            error(message('shared_tracking:blocks:errorJacobianFcnNarginMismatch',...
                fcnName,fcnNargin,jacobianFcnName,jacobianFcnNargin));
        end
        % Nargout must match with the expectation. In case of varargout, we
        % may find -1.
        if hasAdditiveNoise
            expectedNargout = 1;
        else
            expectedNargout = 2;
        end
        if jacobianFcnNargout~=-1 && jacobianFcnNargout~=expectedNargout
            error(message('shared_tracking:blocks:errorMLFcnNargout',...
                jacobianFcnName,expectedNargout,jacobianFcnNargout));
        end
    end
end