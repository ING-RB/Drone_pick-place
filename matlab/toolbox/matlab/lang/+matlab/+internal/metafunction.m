%METAFUNCTION Provides information about a function and its call signature.
%
% MF = METAFUNCTION(ID) returns matlab.internal.metadata.Function or
% matlab.internal.metadata.Method objects corresponding to a function
% identifier. A function identifier is a scalar text that takes one of the
% following formats:
%
%    "foo" - A function on the path, a local function in the file
%    context where metafunction is called, or a constructor with the
%    name foo.
%
%    "MyClass.MyMethod", "MyClass/MyMethod" – Method MyMethod in class
%    MyClass.
%
%    "foo>bar" – Local function bar in file foo.
%
% Example:
%
%    % Get the matlab.meta.Method of MException's constructor method
%    mf = metafunction("MException");
%
% See also MATLAB.INTERNAL.METADATA.CALLSIGNATURE,
% MATLAB.INTERNAL.METADATA.ARGUMENT, MATLAB.INTERNAL.METADATA.VALIDATION.
%
% Copyright 2022 The MathWorks, Inc. 
