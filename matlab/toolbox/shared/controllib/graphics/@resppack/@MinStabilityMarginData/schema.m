function schema
%  SCHEMA  Defines properties for @FreqStabilityMarginData class

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2004 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'AllStabilityMarginData');

% Register class
c = schema.class(pkg, 'MinStabilityMarginData', supclass);

% RE: data units are 
%     frequency: FreqUnits 
%     magnitude: abs
%     phase: degrees