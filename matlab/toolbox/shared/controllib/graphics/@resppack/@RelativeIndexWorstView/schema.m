function schema
%SCHEMA  Defines properties for @RelativeIndexWorstView class

%   Copyright 2021 The MathWorks, Inc.
pkg = findpackage('resppack'); 
schema.class(pkg,'RelativeIndexWorstView', findclass(pkg, 'SigmaPeakRespView'));