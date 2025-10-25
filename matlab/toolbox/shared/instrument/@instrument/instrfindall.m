function output = instrfindall(obj, varargin)
%INSTRFINDALL Find instrument or device group objects with specified property values.
%
%   INSTRFINDALL will be removed in a future release. For serialport,
%   tcpclient, tcpserver, udpport, visadev, aardvark, and ni845x objects,
%   use serialportfind, tcpclientfind, tcpserverfind, udpportfind,
%   visadevfind, aardvarkfind, and ni845xfind instead.
%
%   OUT = INSTRFINDALL returns all instrument objects that exist in memory
%   regardless of the object's ObjectVisibility property value. The instrument
%   objects are returned as an array to OUT.
%
%   OUT = INSTRFINDALL('P1', V1, 'P2', V2,...) returns an array, OUT, of
%   instrument objects or device group objects whose property names and
%   property values match those passed as param-value pairs, P1, V1, P2,
%   V2,... The param-value pairs can be specified as a cell array. 
%
%   OUT = INSTRFINDALL(S) returns an array, OUT, of instrument objects or
%   device group objects whose property values match those defined in
%   structure S whose field names are object property names and the field
%   values are the requested property values.
%   
%   OUT = INSTRFINDALL(OBJ, 'P1', V1, 'P2', V2,...) restricts the search for 
%   matching param-value pairs to the instrument objects or device group
%   objects listed in OBJ. OBJ can be an array of objects.
%
%   Note that it is permissible to use param-value string pairs, structures,
%   and param-value cell array pairs in the same call to INSTRFINDALL.
%
%   When a property value is specified, it must use the same format as
%   GET returns. For example, if GET returns the Name as 'MyObject',
%   INSTRFINDALL will not find an object with a Name property value of
%   'myobject'. However, properties which have an enumerated list data type
%   will not be case sensitive when searching for property values. For
%   example, INSTRFINDALL will find an object with a RecordDetail property value
%   of 'Verbose' or 'verbose'. The data type of a property can be determined 
%   with PROPINFO's Constraint field.
%
%   Example:
%       g1 = gpib('ni', 0, 1, 'Tag', 'Oscilloscope');
%       g2 = gpib('ni', 0, 2, 'Tag', 'FunctionGenerator');
%       set(g1, 'ObjectVisibility', 'off');
%       out1 = instrfind('Type', 'gpib')
%       out2 = instrfindall('Type', 'gpib');
%
%   See also INSTRUMENT/PROPINFO, INSTRUMENT/GET.

%   Copyright 1999-2023 The MathWorks, Inc.

try
    instrument.internal.ICTRemoveFunctionalityHelper(mfilename, "Warn", "Function");
catch ex
    throwAsCaller(ex);
end

try
    output = instrfind(obj, varargin{:});
catch aException
    newExc = MException(strrep(aException.identifier, 'instrfind', 'instrfindall'), aException.message);
    throw(newExc);
end
