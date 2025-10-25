function schema
%  SCHEMA  Defines properties for @ConfidenceRegionIOPZData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionIOPZData', superclass);


schema.prop(c, 'Data', 'MATLAB array');
% Struct Data.Poles     {ny,nu} [npoles-by-1]
%            .Zeros     {ny,nu} [nzeros-by-1]
%            .CovPoles  {ny,nu} [npoles-by-2-by-2]
%            .CovZeros  {ny,nu} [nzeros-by-2-by-2]

schema.prop(c, 'EllipseData', 'MATLAB array');

schema.prop(c, 'Ts',      'MATLAB array');       % Sampling Time
p =schema.prop(c, 'TimeUnits', 'string');  % usings TimeUnits^(-1)
p.FactoryValue = 'seconds';



