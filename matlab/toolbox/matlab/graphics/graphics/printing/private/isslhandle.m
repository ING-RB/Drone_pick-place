function isSL = isslhandle(h)
%ISSLHANDLE True for Simulink object handles for models or subsystem.
%   ISSLHANDLE(H) returns an array that contains 1's where the elements of
%   H are valid printable Simulink object handles and 0's where they are not.

%   Copyright 1984-2020 The MathWorks, Inc.
   isSL = matlab.graphics.internal.isslhandle(h); 
end