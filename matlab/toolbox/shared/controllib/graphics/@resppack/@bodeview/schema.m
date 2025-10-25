function schema
%  SCHEMA  Defines properties for @bodeview class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2005 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'bodeview', superclass);

% Class attributes
schema.prop(c, 'MagCurves', 'MATLAB array');           % Handles of HG lines for mag axes
schema.prop(c, 'MagPosArrows', 'MATLAB array');        % Direction of increasing frequency 
schema.prop(c, 'MagNegArrows', 'MATLAB array');        % Direction of increasing frequency 
schema.prop(c, 'MagNyquistLines', 'MATLAB array');     % Handles of Nyquist lines for mag axes
schema.prop(c, 'PhaseCurves', 'MATLAB array');         % Handles of HG lines for phase axes
schema.prop(c, 'PhasePosArrows', 'MATLAB array');      % Direction of increasing frequency 
schema.prop(c, 'PhaseNegArrows', 'MATLAB array');      % Direction of increasing frequency 
schema.prop(c, 'PhaseNyquistLines', 'MATLAB array');   % Handles of Nyquist lines for phase axes
schema.prop(c, 'UnwrapPhase', 'on/off');               % Phase wrapping
schema.prop(c, 'PhaseWrappingBranch', 'MATLAB array'); % Phase wrapping branch (units in rad)
p = schema.prop(c, 'ComparePhase', 'MATLAB array');    % Phase matching
p.FactoryValue = struct(...
   'Enable', 'off',...
   'Freq', 0, ...
   'Phase', 0);    
schema.prop(c, 'Frequency', 'MATLAB array');  % Underlying frequency vector

 