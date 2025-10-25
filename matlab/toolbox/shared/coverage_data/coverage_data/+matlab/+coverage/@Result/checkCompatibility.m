%

%   Copyright 2022 The MathWorks, Inc.

function varargout = checkCompatibility(this, others)

arguments
    this (:,1) matlab.coverage.Result
    others matlab.coverage.Result = matlab.coverage.Result.empty()
end

% Default outputs (thrown an error only if no output)
throwError = nargout == 0;
status = true;
msg = message.empty;

% Concatenate all the objects for easier access
resObjs = [this; others(:)];

% Only check the execution mode for now
execMode = resObjs(1).ExecutionMode;

% Take the first entry as a reference and check the other results
for ii = 2 : numel(resObjs)
    execModeOther = resObjs(ii).ExecutionMode;
    if execMode ~= execModeOther
        % Generate the error message
        msg = message('MATLAB:coverage:result:CheckIncompExecModes');
        if throwError
            error(msg);
        end
        % Update the outputs and early return
        status = false;
        break
    end
end

% Update the outputs if provided
if nargout > 0
    varargout{1} = status;
    if nargout > 1
        varargout{2} = msg;
    end
end

% LocalWords: CheckIncompExecModes
