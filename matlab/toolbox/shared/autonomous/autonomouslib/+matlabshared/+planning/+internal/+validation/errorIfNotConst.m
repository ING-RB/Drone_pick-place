function errorIfNotConst(x, name)
% errorIfNotConst throws an error during codegen if x is not const
%
%   This is copied from vision.internal.errorIfNotConst.

% Copyright 2018 The MathWorks, Inc.

%#codegen

if ~isempty(coder.target)
    eml_invariant(eml_is_const(x), ...
        eml_message('shared_autonomous:validation:notConst', name));
end

end