function schema
%SCHEMA Define the ImportWorkspace class

% Copyright 2012-2014 The MathWorks, Inc.

%Register class
pk = findpackage('ctrluis');
c  = schema.class(pk, 'ValueEditorImportWorkspace');

%% Class properties
p = schema.prop(c,'Data','mxArray');
p.FactoryValue = [];
p.AccessFlags.PublicGet = 'off';
p.AccessFlags.PublicSet = 'off';

%% Class events
schema.event(c, 'ComponentChanged');
end