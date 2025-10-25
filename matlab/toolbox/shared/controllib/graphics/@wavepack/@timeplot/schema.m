function schema
%SCHEMA  Definition of @timeplot class (time series plot).

%  Author(s): P. Gahinet
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class 
pkg = findpackage('wavepack');
c = schema.class(pkg, 'timeplot', findclass(pkg, 'waveplot'));