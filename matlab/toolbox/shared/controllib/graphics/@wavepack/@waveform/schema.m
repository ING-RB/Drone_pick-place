function schema
%SCHEMA  Class definition of @waveform (time or frequency wave).

%  Author(s): Bora Eryilmaz
%   Copyright 1986-2015 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'dataview');
c = schema.class(findpackage('wavepack'), 'waveform', superclass);

% Public attributes
schema.prop(c, 'Characteristics','handle vector'); % Response char. (@dataview)
schema.prop(c, 'ColumnIndex','MATLAB array');  % Input channels
schema.prop(c, 'Context',        'MATLAB array');  % Context info (plot type, x0,...)
schema.prop(c, 'DataSrc',        'handle');        % Data source (@respsource)
p = schema.prop(c, 'Name',           'ustring');        % Response array name
p.setfunction = {@localSetFunction, 'Name'};
schema.prop(c, 'RowIndex',   'MATLAB array');  % Output channels
schema.prop(c, 'Style',          'handle');        % Style
schema.prop(c, 'Group', 'MATLAB array');    % Curve groups for legend
p = schema.prop(c, 'LegendSubsriptsEnabled', 'MATLAB array');    % Use legend subscripts
p.FactoryValue = false;
% Private attributes
p = schema.prop(c, 'DataChangedListener', 'handle vector');
p = schema.prop(c, 'DataSrcListener', 'handle');
p = schema.prop(c, 'StyleListener', 'handle');
p = schema.prop(c, 'NameListenerData', 'MATLAB array'); % ListenerManager Class
p = schema.prop(c, 'NameListener', 'MATLAB array'); % Virtual ListenerManager Class
p.GetFunction = {@localGetFunction,'NameListener'};
set(p,'AccessFlags.PublicGet','on','AccessFlags.PublicSet','off', ...
    'AccessFlags.PrivateSet','off');  

p = schema.prop(c, 'SelectedListenerData', 'MATLAB array'); % ListenerManager Class
p = schema.prop(c, 'SelectedListener', 'MATLAB array'); % Virtual ListenerManager Class
p.GetFunction = {@localGetFunction, 'SelectedListener'};
set(p,'AccessFlags.PublicGet','on','AccessFlags.PublicSet','off', ...
    'AccessFlags.PrivateSet','off');  

p = schema.prop(c, 'CharacteristicManager', 'MATLAB array');    % Characteristics manager
set(p, 'AccessFlags.PublicGet', 'on', 'AccessFlags.PublicSet', 'off');


p = schema.prop(c, 'DoUpdateName', 'MATLAB array'); % bypass listener flag
% REVISIT: make it private when local function limitation is gone
% set(p, 'AccessFlags.PublicGet', 'off', 'AccessFlags.PublicSet', 'off');

schema.prop(c, 'GroupInfoUpdateFcn', 'MATLAB array');

% Event
schema.event(c, 'DataChanged');



