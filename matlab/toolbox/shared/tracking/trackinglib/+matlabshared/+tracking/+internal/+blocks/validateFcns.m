function [STFcn,MFcn] = validateFcns(dlgParams)
% validateFcns Validate nargin and nargout of MATLAB or Simulink Functions
%              provided to the EKF/UKF/PF blocks
%
% This fcn also throws errors caught earlier while information about the
% fcns were being gathered, in
% matlabshared.tracking.internal.blocks.getFunctionInfo

%   Copyright 2017 The MathWorks, Inc.

% StateTransitionFcn
S = dlgParams.FcnInfo.Predict;
expectedNargout = 1;
[STFcn.Name, STFcn.IsSimulinkFcn, STFcn.NumberOfExtraArgumentInports] = ...
    localValidateFcn(S.Fcn{1}, S.FcnType{1},...
    S.FcnNargin(1), S.FcnNargout(1), S.FcnErrors{1}, ...
    S.ExpectedNargin, expectedNargout);

% Measurement(Likelihood)Fcn
S = dlgParams.FcnInfo.Correct;
MFcn.Name = cell(dlgParams.NumberOfMeasurements,1);
MFcn.IsSimulinkFcn = false(dlgParams.NumberOfMeasurements,1);
MFcn.NumberOfExtraArgumentInports = zeros(dlgParams.NumberOfMeasurements,1);
for kk=1:dlgParams.NumberOfMeasurements
    if isfield(dlgParams,'HasMeasurementWrapping') && ...
       dlgParams.HasMeasurementWrapping(kk) == 1
       expectedNargout = 2;
    else
       expectedNargout = 1;
    end
    [MFcn.Name{kk}, MFcn.IsSimulinkFcn(kk), MFcn.NumberOfExtraArgumentInports(kk)] = ...
    localValidateFcn(S.Fcn{kk}, S.FcnType{kk},...
        S.FcnNargin(kk), S.FcnNargout(kk), ...
        S.FcnErrors{kk}, S.ExpectedNargin(kk), expectedNargout);
end
end

function [fcnName, isSimulinkFcn, numberOfExtraArgumentInports] = ...
    localValidateFcn(fcnName, fcnType, fcnNargin, fcnNargout, fcnErrors, expectedNargin, expectedNargout)
% Throw the errors that were caught during function processing
if ~isempty(fcnErrors)
    error(fcnErrors)
end

isSimulinkFcn = strcmp(fcnType,'SimulinkFcn');
% Function type specific error checks: nargin&nargout
if isSimulinkFcn
    % * Unlike MLFcn case, there is no varargin/varargout
    % * We are blind to extra inputs (no extra argument inports)
    numberOfExtraArgumentInports = 0;
    
    if fcnNargin~=expectedNargin
        error(message('shared_tracking:blocks:errorSLFcnNargin',fcnName,expectedNargin,fcnNargin));
    end
    if fcnNargout~=expectedNargout
        error(message('shared_tracking:blocks:errorSLFcnNargout',fcnName,expectedNargout,fcnNargout));
    end
else
    % Check nargin & nargout:
    % * If fcns have varargin/varargout, we may find -1
    % * If there is an extra input, we may find expectedNargin+1
    if fcnNargin~=-1 && fcnNargin~=expectedNargin && fcnNargin~=expectedNargin+1
        error(message('shared_tracking:blocks:errorMLFcnNargin',fcnName,expectedNargin,expectedNargin+1,fcnNargin));
    end
    if fcnNargout~=-1 && fcnNargout~=expectedNargout
        error(message('shared_tracking:blocks:errorMLFcnNargout',fcnName,expectedNargout,fcnNargout));
    end
    
    % Maximum 1 extra inports per state transition or measurement fcn is
    % supported. 
    % * The checks above ensure this.
    % * Treat varargin case as no extra argument inports
    if fcnNargin~=-1
        numberOfExtraArgumentInports = fcnNargin-expectedNargin;
    else
        numberOfExtraArgumentInports = 0; % varargin
    end
end
end
