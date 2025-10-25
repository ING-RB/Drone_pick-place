function [data, view, dataprops] = createdataview(this, Nresp)
%CREATEDATAVIEW  Create @data and @view "product" objects to be associated
%                with a @waveform "client" object.

%   Copyright 2013-2015 The MathWorks, Inc.
for ct = Nresp:-1:1
   % Create data objects
   data(ct,1) = iodatapack.IOTimeData;
   data(ct,1).IsReal = true;
   
   % Create view objects
   view(ct,1) = iodatapack.IOTimeView;
   view(ct).AxesGrid = this.AxesGrid;
end

% Return list of data-related properties of data object
dataprops = [data(1).findprop('InputData'); data(1).findprop('OutputData')];
