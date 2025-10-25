function [data, view, dataprops] = createdataview(this, Nresp,ViewClass)
%  CREATEDATAVIEW  Abstract Factory method to create @respdata and
%                  @respview "product" objects to be associated with
%                  a @response "client" object H.

%  Author(s): Kamesh Subbarao
%  Copyright 1986-2004 The MathWorks, Inc.


if nargin < 3
    DataClass = 'resppack.pzdata';
    ViewClass = 'resppack.pzview';
elseif strcmp(ViewClass,'resppack.SpectralBoundView')
    DataClass = 'resppack.SpectralBoundData';
end

for ct = Nresp:-1:1
  % Create @respdata objects
  data(ct,1) = feval(DataClass);
  % Create @respview objects
  view(ct,1) = feval(ViewClass);
end
set(view,'AxesGrid',this.AxesGrid) 
% Return list of data-related properties of data object
% Revisit turn this into a method on the data object
if isa(data(1),'resppack.pzdata')
    dataprops = [data(1).findprop('Poles');data(1).findprop('Zeros');data(1).findprop('Ts')];
elseif isa(data(1),'resppack.SpectralBoundData')
    dataprops = [data(1).findprop('SpectralAbscissa');data(1).findprop('SpectralRadius')];
end


