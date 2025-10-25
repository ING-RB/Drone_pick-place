function inspect(obj)
%INSPECT Inspect instrument or device group object properties.
%
%   INSPECT(OBJ) opens the property inspector and allows you to
%   inspect and set properties for instrument object or device group
%   object, OBJ.
%
%   Example:
%       g = gpib('agilent', 0, 2);
%       d = icdevice('agilent_e3648a', g);
%       outputs = d.Output;
%       inspect(g);
%       inspect(outputs(1));
%
%   See also INSTRUMENT/SET, INSTRUMENT/GET, INSTRUMENT/PROPINFO,
%   ICGROUP/SET, ICGROUP/GET, ICGROUP/PROPINFO, INSTRHELP.

%   Copyright 1999-2021 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'instrument')
    error(message('instrument:inspect:invalidOBJInstrument'));
end

if ~isvalid(obj)
    error(message('instrument:inspect:invalidOBJ'));
end

% Launch the UI Inspector containing the inspected object.
instrument.internal.PropertyInspectorFactory.inspectObject(obj, inputname(1));