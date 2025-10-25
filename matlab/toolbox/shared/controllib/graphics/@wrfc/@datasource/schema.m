function schema
%SCHEMA  Class definition for @datasource (abstract data source).

%  Author(s): P. Gahinet
%  Copyright 1986-2015 The MathWorks, Inc.

% Register class
pkg = findpackage('wrfc');
c = schema.class(pkg, 'datasource');

% Class attributes
schema.prop(c, 'Name', 'ustring');        % Source name

% Private attributes
p = schema.prop(c, 'Listeners', 'handle vector');
set(p, 'AccessFlags.PublicGet', 'off', 'AccessFlags.PublicSet', 'off');

% Class events
schema.event(c, 'SourceChanged');
