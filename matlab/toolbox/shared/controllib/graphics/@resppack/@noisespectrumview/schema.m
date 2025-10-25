function schema
%  SCHEMA  Defines properties for @noisespectrumview class.

%  Copyright 1986-2018 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'noisespectrumview', superclass);

% Class attributes
schema.prop(c, 'MagCurves', 'MATLAB array');          % Handles of HG lines for mag axes
schema.prop(c, 'MagNyquistLines', 'MATLAB array');    % Handles of Nyquist lines for mag axes

% For predmaint use
schema.prop(c, 'Context', 'MATLAB array');
schema.prop(c, 'MagPatches', 'MATLAB array');         % Handles of ensemble patches
schema.prop(c, 'MinLines',   'MATLAB array');         % per-frequency ensemble min for a spectrum
schema.prop(c, 'MaxLines',   'MATLAB array');         % per-frequency ensemble max for a spectrum
schema.prop(c, 'MeanLines',   'MATLAB array');        % per-frequency ensemble mean for a spectrum
schema.prop(c, 'DrawnFrameRange',   'MATLAB array');  % start time range of rendered frames