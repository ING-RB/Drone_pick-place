function schema
% Defines properties for @axesselector class (row/column selector)

%   Copyright 1986-2015 The MathWorks, Inc.

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'axesselector');

% General
schema.prop(c,'ColumnName','MATLAB array');         % Column labels
schema.prop(c,'ColumnSelection','MATLAB array');     % Selected cols (bool vector)
schema.prop(c,'Name','ustring');                      % Selector name
schema.prop(c,'RowName','MATLAB array');            % Row labels
schema.prop(c,'RowSelection','MATLAB array');        % Selected rows (bool vector)
schema.prop(c,'Visible','on/off');                   % Selector visibility
schema.prop(c,'Size','MATLAB array');                % Row/Col size
p = schema.prop(c,'Style','MATLAB array');           % Style params
p.FactoryValue = struct('OnColor',[0 0 0],'OffColor',[.8 .8 .8]);         

% Private
% REVISIT: make private when private prop can be accessed in local functions of methods
p(2) = schema.prop(c,'Handles','MATLAB array');      % HG handles
p(2) = schema.prop(c,'Listeners','handle vector');   % Listeners
%set(p,'AccessFlags.PublicGet','off','AccessFlags.PublicSet','off')
