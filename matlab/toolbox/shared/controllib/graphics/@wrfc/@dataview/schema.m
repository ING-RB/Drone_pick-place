function schema
%SCHEMA  Definition of @dataview interface (abstract plot component).
%
%  This class holds both the data and the view objects for each plot
%  component.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2014 The MathWorks, Inc.

% Register class 
pkg = findpackage('wrfc');
c = schema.class(pkg, 'dataview');

% Public attributes
schema.prop(c, 'Data',    'handle vector');  % Data objects (@data)
schema.prop(c, 'DataFcn', 'MATLAB array');   % Function for updating data
schema.prop(c, 'Description', 'ustring');     % Component description
schema.prop(c, 'Parent',  'handle');         % Parent object
p = schema.prop(c, 'RefreshMode', 'string'); % Graphics update mode
p.FactoryValue = 'normal';                   % RefreshMode: [{normal} | quick]
schema.prop(c, 'RefreshFocus', 'MATLAB array');% Optionally specifies X focus to speed up refresh
schema.prop(c, 'View',    'handle vector');  % View objects (@view)
p = schema.prop(c, 'Visible', 'on/off');     % Visibility of overall component
p.FactoryValue = 'on';                    

% Private attributes
p = schema.prop(c, 'Listeners', 'handle vector');
set(p, 'AccessFlags.PublicGet', 'off', 'AccessFlags.PublicSet', 'off');
