function schema
%SCHEMA  Defines properties for @nyquistview class.

%  Author(s): P. Gahinet
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'nyquistview', superclass);

% Class attributes
schema.prop(c, 'Curves', 'MATLAB array');     % Nyquist curves
schema.prop(c, 'PosArrows', 'MATLAB array');  % Arrows for positive freqs
schema.prop(c, 'NegArrows', 'MATLAB array');  % Arrows for negative freqs
p = schema.prop(c, 'ShowFullContour', 'bool');% 1 -> show branch for w<0
p.FactoryValue = 1;
schema.prop(c, 'Frequency', 'MATLAB array');  % Underlying frequency vector