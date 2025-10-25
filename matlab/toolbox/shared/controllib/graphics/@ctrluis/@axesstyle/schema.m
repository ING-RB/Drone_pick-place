function schema
% Defines properties for @axesstyle class

%   Copyright 1986-2014 The MathWorks, Inc. 

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'axesstyle');

% Properties
schema.prop(c,'Color','MATLAB array');    % Axes color
schema.prop(c,'FontAngle','string');      % Font angle
schema.prop(c,'FontSize','double');       % Font size
schema.prop(c,'FontWeight','string');     % Font weight
schema.prop(c,'XColor','MATLAB array');   % X axis color

schema.prop(c,'YColor','MATLAB array');   % Y axis color

schema.prop(c,'GridColor','MATLAB array');   % Grid axis color

schema.prop(c,'ColorContainer','MATLAB array'); % Color container widget

schema.prop(c,'XColorMode','MATLAB array');
schema.prop(c,'YColorMode','MATLAB array');
schema.prop(c,'GridColorMode','MATLAB array');

% Style update function
schema.prop(c,'UpdateFcn','MATLAB callback');

% Listeners
p = schema.prop(c,'Listeners','handle vector');        % Listeners
set(p,'AccessFlags.PublicGet','off','AccessFlags.PublicSet','off');  
