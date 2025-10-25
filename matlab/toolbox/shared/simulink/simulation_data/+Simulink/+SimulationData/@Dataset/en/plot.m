% SIMULINK.SIMULATIONDATA.DATASET.PLOT(ds, viewer) - plots the elements of
% a dataset
%
%       ds : The Simulink.SimulationData.Dataset that contains 
%            the elements to plot.
%
%   viewer : Optional input to select UI to display the data. 
%      'datainspector' : display in Simulation Data Inspector [default]
%            'preview' : display in Signal Preview
%
%   EXAMPLE:
%      >> ts = timeseries([0;20],[0;10]);
%      >> ds = Simulink.SimulationData.Dataset();
%      >> ds = ds.addElement(ts,'ts');
%      >> plot(ds);
%
%      >> plot(ds, 'preview');

     
% Copyright 2009-2024 The MathWorks, Inc.

