function schema
%SCHEMA  Defines properties for @NyquistPeakRespView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('resppack'), 'NyquistPeakRespView', superclass);

% Public attributes
schema.prop(c, 'Lines', 'MATLAB array');     % Dashed lines from origin to peak