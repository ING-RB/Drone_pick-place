function out = fieldnames(obj, flag)
%FIELDNAMES Get instrument or device group object property names.
%
%   NAMES=FIELDNAMES(OBJ) returns a cell array of strings containing 
%   the names of the properties associated with instrument object or
%   device group object, OBJ. OBJ can be an array of instrument objects
%   or an array of device group objects.
%

%   MP 3-14-02
%   Copyright 1999-2011 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2011/05/13 18:06:09 $

if ~isa(obj, 'instrument')
    error(message('instrument:fieldnames:invalidOBJInstrument'));
end

% Error if invalid.
if ~all(isvalid(obj))
   error(message('instrument:fieldnames:invalidOBJ'));
end

try
    out = fieldnames(get(obj));
catch
    error(message('instrument:fieldnames:invalidOBJMixed'));
end
