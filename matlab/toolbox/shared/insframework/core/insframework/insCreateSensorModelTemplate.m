function insCreateSensorModelTemplate(name)
%INSCREATESENSORMODELTEMPLATE creates a template file for a sensor model
%   to be used with the insEKF. The template is opened in the MATLAB
%   Editor. The input NAME is the class name of the new sensor.
%
%   Example:
%       insCreateSensorModelTemplate("mysensor");
%
%   See also: insEKF, insCreateMotionModelTemplate

%   Copyright 2022 The MathWorks, Inc.    

% Validate name is a valid file name

% Code generation is not supported/needed for this. 
% So no codegen pragma, and using assert vs coder.internal.assert

narginchk(1,1);

s = isStringScalar(name) || ischar(name);
val = isvarname(name);
assert(s && val, message('insframework:insEKF:ExpectedValidClassName'));

writer = positioning.internal.SensorWriterPlugin;
writer.writeTemplate(name);
writer.writeContentsToEditor;

