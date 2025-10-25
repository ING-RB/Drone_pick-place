function b = uminus(a) %#codegen
% UMINUS Negation for durations.

%   Copyright 2019 The MathWorks, Inc.
b = a;
b.millis = -a.millis;

