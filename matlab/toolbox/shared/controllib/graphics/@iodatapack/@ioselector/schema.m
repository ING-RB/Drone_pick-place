function schema
% Defines properties for @ioselector class.

%   Copyright 2013-2015 The MathWorks, Inc.

% Register class 
pk = findpackage('iodatapack');
c = schema.class(pk,'ioselector');

% General
schema.prop(c,'InputName','MATLAB array');         
schema.prop(c,'OutputName','MATLAB array');     
schema.prop(c,'InputSelected','MATLAB array');       % bool vector
schema.prop(c,'OutputSelected','MATLAB array');      % bool vector
schema.prop(c,'Visible','on/off');                   % Selector visibility

schema.prop(c,'Handles','MATLAB array');      % HG handles
schema.prop(c,'Listeners','handle vector');   % Listeners
