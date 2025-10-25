function schema
%SCHEMA  Defines properties for @SpectralBoundView class

%   Author(s): Craig Buhr
%   Copyright 1986-2012 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'SpectralBoundView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'SpectralRadiusPatch', 'MATLAB array');    % Handles of HG Patch (matrix)
schema.prop(c, 'SpectralAbscissaPatch', 'MATLAB array');  % Handles of HG Patch (matrix)

