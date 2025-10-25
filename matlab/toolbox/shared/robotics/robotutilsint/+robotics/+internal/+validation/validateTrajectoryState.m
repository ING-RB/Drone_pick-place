function validState = validateTrajectoryState(state,functionName, varName)
%This function is for internal use only. It may be removed in the future.

%validateTrajectoryState Validate trajectory states
%   Validate 6-vector double states to be nonempty, finite and real.

%   Copyright 2019-2023 The MathWorks, Inc.

%#codegen
    validateattributes(state, {'numeric'},{'nonempty','finite','real','vector', 'numel', 6},functionName,varName);

    % Ensure that validated state is always a column vector
    validState = double(state(:)');
end
