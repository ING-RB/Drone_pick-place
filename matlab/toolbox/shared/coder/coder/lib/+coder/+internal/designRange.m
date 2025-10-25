function value = designRange(targetVar, rangeMin, rangeMax)
%MATLAB Code Generation Private Function

%   This is an internal variant of coder.designRange which bypasses the
%   validation of "compile-time characteristics" and only performs the runtime
%   check against the value targeted by the design range constraints.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
coder.internal.userReadableName('');

idxFail = findFirst(@(x) ~(x >= rangeMin && x <= rangeMax), double(targetVar));
if idxFail > 0 % This prevents an error at line 15 during Matlab execution.
    coder.internal.errorIf(idxFail > 0, 'EMLRT:runTime:OutOfDesignRange', ...
                           coder.internal.num2str(double(targetVar(idxFail))), ...
                           coder.internal.num2str(rangeMin), ...
                           coder.internal.num2str(rangeMax));
end

value = targetVar;
end

function idx = findFirst(pfun, x)
    idx = coder.internal.indexInt(0);
    for k = coder.internal.indexInt(numel(x)):-1:1
        if pfun(x(k))
            idx = k;
            % No break or return here in order to generate cleaner/faster code;
            % We assume that in the general case, no failures are found.
        end
    end
end
