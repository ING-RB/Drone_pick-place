function schema
%SCHEMA  Class definition of @hsvchart (Hankel singular value bar chart).

%  Author(s): P. Gahinet
%  Copyright 1986-2015 The MathWorks, Inc.

% Register class 
superclass = findclass(findpackage('wrfc'), 'dataview');
c = schema.class(findpackage('resppack'), 'hsvchart', superclass);

% Public attributes
schema.prop(c, 'DataSrc',        'handle');        % Data source (@respsource)
schema.prop(c, 'Name',           'ustring');       % System name

% Private attributes
schema.prop(c, 'DataChangedListener', 'handle vector');
schema.prop(c, 'DataSrcListener', 'handle');

% Event
schema.event(c, 'DataChanged');
