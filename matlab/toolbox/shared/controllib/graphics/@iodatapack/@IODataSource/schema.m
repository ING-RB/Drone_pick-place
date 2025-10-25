function schema
%SCHEMA  Defines properties specific to @IODataSource class.
% Used to plot and process @iddata, @sdo.Experiment.

%   Copyright 2013-2017 The MathWorks, Inc.

% Find parent package
pkg = findpackage('iodatapack');

% Register class
superclass = findclass(findpackage('wrfc'),'datasource');
c = schema.class(pkg, 'IODataSource', superclass);

p = schema.prop(c, 'IOSize', 'MATLAB array');
p.GetFunction = {@getIOSize};

% Essential data used for plotting and processing.
% An ltipack.InputOutputData object representing a single experiment of a
% dataset.
p = schema.prop(c, 'IOData', 'MATLAB array');

p = schema.prop(c, 'UsePreview', 'MATLAB array');
p.FactoryValue = false;

p = schema.prop(c, 'IsReal', 'MATLAB array');
p.FactoryValue = true;

schema.prop(c, 'IODataChangeListener', 'MATLAB array');
