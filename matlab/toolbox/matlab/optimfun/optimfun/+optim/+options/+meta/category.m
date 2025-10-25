function c = category(key)
%CATEGORY Get formatted option category string

%   Copyright 2019 The MathWorks, Inc.

    c = getString(message(['MATLAB:optimfun:options:meta:categories:' key]));
end