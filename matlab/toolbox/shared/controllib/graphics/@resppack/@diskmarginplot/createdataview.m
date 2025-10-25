function [data, view, dataprops] = createdataview(this, Nresp, ViewClass)
% Abstract Factory method to create @respdata and @respview "product" 
% objects to be associated with a @response "client".

%  Copyright 1986-2014 The MathWorks, Inc.
if nargin<3
   ViewClass = 'resppack.diskmarginview';
end
   
for ct = Nresp:-1:1
   % Create @respdata objects
   data(ct,1) = resppack.diskmargindata;
   % Create @respview objects
   view(ct,1) = feval(ViewClass);
end
set(view,'AxesGrid',this.AxesGrid)

% Return list of data-related properties of data object
dataprops = [data(1).findprop('Frequency'); ...
      data(1).findprop('Magnitude'); data(1).findprop('Phase')];