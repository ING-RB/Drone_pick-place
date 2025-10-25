function tf = isnan(a)
%

%   Copyright 2014-2024 The MathWorks, Inc.

components = a.components;
% A scalar zero placeholder is a no-op for this test.
tf = isnan(components.months) | isnan(components.days) | isnan(components.millis);
