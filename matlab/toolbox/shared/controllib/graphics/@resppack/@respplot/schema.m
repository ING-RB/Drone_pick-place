function schema
%SCHEMA  Class definition for @respplot (response plot)

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2015 The MathWorks, Inc.

% Extends @wrfc/@plot interface
cplot = findclass(findpackage('wrfc'), 'plot');

% Register class 
c = schema.class(findpackage('resppack'), 'respplot', cplot);

% Class attributes
p = schema.prop(c, 'InputName',    'MATLAB array');  % Input names (cell array)
p.setfunction = {@localSetFunction, 'InputName'};
schema.prop(c, 'InputVisible', 'string vector');  % Visibility of individual input channels
p = schema.prop(c, 'IOGrouping', 'string');       % [{none}|all|inputs|outputs]
p.FactoryValue = 'none';
p = schema.prop(c, 'OutputName',    'MATLAB array'); % Output names (cell array)
p.setfunction = {@localSetFunction, 'OutputName'};
schema.prop(c, 'OutputVisible', 'string vector'); % Visibility of individual output channels
schema.prop(c, 'Responses',  'handle vector');    % Response arrays (@waveform)

% Property Editor widgets
p = schema.prop(c,'UnitsContainer','MATLAB array');
p = schema.prop(c,'NoOptionsLabel','MATLAB array');
p = schema.prop(c, 'TimeResponseContainer', 'MATLAB array');
p = schema.prop(c, 'MagnitudeResponseContainer', 'MATLAB array');
p = schema.prop(c, 'PhaseResponseContainer', 'MATLAB array');
p = schema.prop(c, 'ConfidenceRegionContainer', 'MATLAB array');