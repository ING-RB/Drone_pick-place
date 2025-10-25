function lbl = label(key)
%LABEL Get formatted option label string

%   Copyright 2019 The MathWorks, Inc.

lbl = getString(message(['MATLAB:optimfun:options:meta:labels:' key]));
end