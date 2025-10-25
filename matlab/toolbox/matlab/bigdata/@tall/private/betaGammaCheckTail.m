function betaGammaCheckTail(tail,name,argPos,validTail)
%betaGammaCheckTail  Check the "tail" argument for betainc/gamminc.

%   Copyright 2016-2021 The MathWorks, Inc.

tall.checkNotTall(upper(name), argPos, tail);

% Check we have a string that matches exactly one of the supplied flags.
if ~isNonTallScalarString(tail) ...
        || nnz(startsWith(validTail,tail,"IgnoreCase",true)) ~= 1
    errId = ['MATLAB:', name, ':InvalidTailArg'];
    throwAsCaller(MException(message(errId)));
end
end
