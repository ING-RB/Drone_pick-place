function tf = isfinite(a)
%

%   Copyright 2014-2024 The MathWorks, Inc.

components = a.components;
% A scalar zero placeholder is a no-op for this test.
tf = isfinite(components.months) & isfinite(components.days) & isfinite(components.millis);
