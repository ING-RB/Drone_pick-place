function schema
%SCHEMA  Defines properties for @rldata class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2010 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'rldata', supclass);

% Class attributes
schema.prop(c,'Gains','MATLAB array');        % Locus gains (ngains-by-1)
schema.prop(c,'Roots','MATLAB array');        % Locus roots (ngains-by-nbranches)
schema.prop(c,'SystemGain', 'double');        % System gain
schema.prop(c,'SystemZero', 'MATLAB array');  % System zeros
schema.prop(c,'SystemPole', 'MATLAB array');  % System poles
schema.prop(c,'Ts','double');                 % Sample time (for equivalent frequency)
schema.prop(c,'XFocus', 'MATLAB array');      % X-Focus (preferred X range)
schema.prop(c,'YFocus', 'MATLAB array');      % Y-Focus (preferred Y range)
p =schema.prop(c, 'TimeUnits', 'string');  % usings TimeUnits^(-1)
p.FactoryValue = 'seconds';
