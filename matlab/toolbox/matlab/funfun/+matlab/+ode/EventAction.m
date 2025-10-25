%matlab.ode.EventAction  Enumeration of event responses.

%    Copyright 2023 MathWorks, Inc.

classdef (Sealed = true) EventAction < int8
    enumeration
        proceed(1)
        stop(0)
        callback(-1)
    end
end
