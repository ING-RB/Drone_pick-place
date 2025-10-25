function schema
%SCHEMA  Defines properties for @nicholsview class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2005 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'nicholsview', superclass);

% Class attributes
schema.prop(c, 'Curves', 'MATLAB array');              % Handles of HG lines
schema.prop(c, 'UnwrapPhase', 'on/off');               % Phase wrapping
schema.prop(c, 'PhaseWrappingBranch', 'MATLAB array'); % Phase wrapping branch (units in rad)
p = schema.prop(c, 'ComparePhase', 'MATLAB array');    % Phase matching
p.FactoryValue = struct(...
   'Enable', 'off',...
   'Freq', 0, ...
   'Phase', 0); 