function schema
%SCHEMA  Defines properties specific to @idnoisemodelsrc class.
% This class manages plots of time series models (currently only the
% spectrum plot). 

% Subclassing is required to treat the 'unmeasured' input as the measured
% one. Simply converting the noise measured to a measured one does not work
% because "spectrum" related algorithms still apply to the "H" transfer
% function of the model in y = Gu + He.

%  Author(s): Rajiv Singh
%  Copyright 2011 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class 
c = schema.class(pkg, 'idnoisemodelsrc', findclass(pkg, 'ltisource'));

