function f = addExtensionIfNeeded(f, fext)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

[fp, fn, fe] = fileparts(f);
fe(fe == "") = fext;
f = fullfile(fp, fn + fe);
end
