function caller = getSigMaskHelperCaller(handle)
%getSigMaskHelperCaller(HANDLE)
%   Mask helper utility function.
%
%   From handle argument, determines if it is being called from a Simulink
%   block, a System object, or an EML function. Can be used to decide what
%   error or warning message to emit.
%
%   Returns 0 if handle is a Simulink block handle (gcbh) Returns 1 if
%   handle is a System object block handle Returns 2 if handle is a System
%   object block handle and the system object is called by an EML function.
%   (Not implemented)

%   Copyright 2010-2015 The MathWorks, Inc.

%#codegen

narginchk(1,1);

if isa(handle, 'matlab.system.SystemImpl')
    caller = 1;
else
    caller = 0;
end

end % sigGetMaskHelperCaller

