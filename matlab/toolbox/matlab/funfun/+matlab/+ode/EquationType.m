%matlab.ode.EventAction  Enumeration of equation types.

%    Copyright 2024 MathWorks, Inc.

classdef (Sealed = true) EquationType < int8
    enumeration
        standard(0)
        fullyimplicit(1)
        delay(2)
    end
end
