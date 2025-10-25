function b = uminus(a)
%

%   Copyright 2018-2024 The MathWorks, Inc.

b = a;
b_components = b.components;
b_components.months = -b_components.months;
b_components.days   = -b_components.days;
b_components.millis = -b_components.millis;
b.components = b_components;
