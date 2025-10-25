function [data, view, dataprops] = createdataview(this, Nresp)
%  CREATEDATAVIEW  Abstract Factory method to create @respdata and
%                  @respview "product" objects to be associated with
%                  a @response "client" object H.

%  Copyright 2013 The MathWorks, Inc.
for ct = Nresp:-1:1
   % Create data objects
   data(ct,1) = iodatapack.IOFrequencyData;
   % Create view objects
   view(ct,1) = iodatapack.IOFrequencyView;
end
set(view,'AxesGrid',this.AxesGrid)

% Return list of data-related properties of data object
dataprops = [data(1).findprop('Frequency'); ...
      data(1).findprop('Magnitude');...
      data(1).findprop('Phase')];
