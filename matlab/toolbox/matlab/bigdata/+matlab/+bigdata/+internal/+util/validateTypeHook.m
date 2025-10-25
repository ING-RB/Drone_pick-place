function out = validateTypeHook(hookOrData, methodName, argIdx, allowedTypes, forbiddenTypes)
% validateTypeHook Hook function to instrument calls to tall.validateType and
% tall.validateTypeWithError.
%    oldHook = validateTypeHook(newHook) sets up a new hook function.
%    A hook function must have the following API:
%    data = hookFcn(data, methodName, argIdx, allowedTypes, forbiddenTypes)
%    The hook can add operations to the lazy evaluation graph by adding operations to 'data'. 
%    Specifying an empty value for 'hook' disables the hook.
%
%    To invoke the installed hook function, call this function with the 5 arguments defined above
%    for the hook.

% Copyright 2018 The MathWorks, Inc.

persistent VALIDATE_TYPE_LOG_HOOK

if nargin == 1 
    assert(isa(hookOrData, 'function_handle') || isempty(hookOrData), ...
           'Hook supplied to validateTypeHook must be either a function_handle or empty.');
    % Set the hook
    out = VALIDATE_TYPE_LOG_HOOK;
    VALIDATE_TYPE_LOG_HOOK = hookOrData;
else
    narginchk(5,5);
    % Call the hook if installed
    if isempty(VALIDATE_TYPE_LOG_HOOK)
        out = hookOrData;
    else
        out = VALIDATE_TYPE_LOG_HOOK(hookOrData, methodName, argIdx, allowedTypes, forbiddenTypes);
    end
end
end
