function [pool, errorStruct] = resolveUseParallelForApp(useParallelOption)
% resolveUseParallelForApp Resolve a UseParallel request from the user in an app
%
%   Use matlab.internal.parallel.resolveUseParallelForApp to validate the
%   toggle button "Use Parallel" in a toolbox App. This button enables CPU
%   parallelization with parallel pools and Parallel Computing Toolbox.
%
%   [pool, errorStruct] =
%   matlab.internal.parallel.resolveUseParallelForApp("on") returns a
%   non-empty parallel.Pool instance. If one cannot be created for any
%   reason, then errorStruct is a struct with the error message ID
%   and its corresponding text. For backwards compatibility, you can also
%   provide true as the input option to enable the same behavior as "on".
%
%   [pool, errorStruct] =
%   matlab.internal.parallel.resolveUseParallelForApp("off") returns
%   parallel.Pool.empty() in all cases. For backwards compatibility, you
%   can also provide false as the input option to enable the same behavior
%   as "off".
%
% Example of usage:
% function RunButtonPushed(app, event)
%
%   [pool, errorStruct] = matlab.internal.parallel.resolveUseParallelForApp(app.UseParallel);
%   if ~isempty(errorStruct)
%       % Create Alert dialog following Parula with the information in
%       % errorStruct: errorID and errorMessage.
%   elseif isempty(pool) % empty parallel.Pool object
%       % Run computation on CPU
%       disp('Run on CPU');
%   else
%       % Run computation on Parallel pool
%       disp('Run on parallel pool.');
%   end
%
% end
%
%   See also canUseParallelPool, parallel.Pool, parpool.

%   Copyright 2024 The MathWorks, Inc.

nargoutchk(2,2);

try
    errorStruct = [];
    useParallelOption = validateLogicalScalarOrOnOff(useParallelOption, ...
        "MATLAB:parallel:pool:InvalidUseParallelForApp");
    pool = matlab.internal.parallel.resolveUseParallel(useParallelOption);
catch E
    pool = parallel.Pool.empty();
    errorStruct.errorID = E.identifier;
    errorStruct.errorMessage = E.message;
end
end

