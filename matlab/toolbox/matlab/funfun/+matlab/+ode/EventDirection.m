%ODESolver.Eventdirection  Enumeration of event direction settings.

%    Copyright 2023 MathWorks, Inc.

classdef (Sealed = true) EventDirection < int8
    enumeration
        both(0)
        ascending(1)
        descending(-1)
    end
end
