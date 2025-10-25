function schema
% SCHEMA Class definition for @fftplot 

% Author(s): Erman Korkut 12-Mar-2009
% Revised:
% Copyright 1986-2009 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');
c = schema.class(pkg, 'sinestreamplot', findclass(pkg, 'timeplot'));
% schema.prop(c, 'FreqIndices', 'MATLAB array');
% schema.prop(c, 'RespIndices', 'MATLAB array');
% schema.prop(c, 'RespAvailable', 'MATLAB array');


