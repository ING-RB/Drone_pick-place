%matlab.ode.SolverID  Enumeration of valid Solver selections.

%    Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) SolverID < int8
    enumeration
        % Automatic solver selection modes get negative numbers.
        stiff(-3) 
        nonstiff(-2)
        auto(-1)
        % Solvers get positive numbers.
        ode23(1)
        ode45(2)
        ode78(3)
        ode89(4)
        ode113(5)
        ode15s(6)
        ode23s(7)
        ode23t(8)
        ode23tb(9)
        cvodesstiff(10)
        cvodesnonstiff(11)
        idas(12)
        ode15i(13)
        dde23(14)
        ddesd(15)
        ddensd(16)
    end
    enumeration(Hidden)
        % aliased IDs for old solver names
        cvodesStiff(10)
        cvodesNonstiff(11)
    end
end