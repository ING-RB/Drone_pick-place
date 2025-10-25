function inspect(obj)
%INSPECT Open inspector and inspect serial port object properties.
%
%   INSPECT(OBJ) opens the property inspector and allows you to
%   inspect and set properties for serial port object, OBJ.
%
%   Example:
%       s = serial('COM2');
%       inspect(s);
%
%   See also SERIAL/SET, SERIAL/GET.
%

%   Copyright 1999-2021 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'instrument')
    error(message('MATLAB:serial:inspect:invalidOBJInstrument'));
end

if ~isvalid(obj)
    error(message('MATLAB:serial:inspect:invalidOBJ'));
end

% Launch the UI Inspector containing the inspected object.
instrument.internal.PropertyInspectorFactory.inspectObject(obj, inputname(1));