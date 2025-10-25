function schema
%SCHEMA  Defines properties for @rlview class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2009 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'rlview', superclass);

% Public properties
p = schema.prop(c, 'BranchColorList', 'MATLAB array');   % Branch coloring scheme
p.FactoryValue = cell(1,0);  % default = inherit from response style
p = schema.prop(c, 'Locus', 'MATLAB array');  % Handles of locus lines (vector)
p.SetFunction = @localConvertToHandle;
p = schema.prop(c, 'SystemZero', 'MATLAB array');    % Handles of system zeros
p.SetFunction = @localConvertToHandle;
p = schema.prop(c, 'SystemPole', 'MATLAB array');    % Handles of system poles
p.SetFunction = @localConvertToHandle;

