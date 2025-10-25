function schema
%SCHEMA  Defines properties for @FreqPeakGainView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('wavepack'), 'FreqPeakGainView', superclass);

% Public attributes
schema.prop(c, 'VLines', 'MATLAB array');    % Handles of vertical lines 
schema.prop(c, 'HLines', 'MATLAB array');    % Handles of horizontal lines 