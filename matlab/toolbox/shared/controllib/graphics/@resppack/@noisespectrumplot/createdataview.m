function [data, view, dataprops] = createdataview(this, Nresp, varargin)
%  CREATEDATAVIEW  Abstract Factory method to create @respdata and
%                  @respview "product" objects to be associated with
%                  a @response "client" object H.

%  Copyright 1986-2018 The MathWorks, Inc.

if ~isempty(this.Context) && strcmp(this.Context.PlotType,"pspectrum")
   data = resppack.noisespectrumdata;
   view = resppack.noisespectrumview;
   P = this.Context;
   data.Context = P;
   view.Context = P;
else
   for ct = Nresp:-1:1
      % Create @respdata objects
      data(ct,1) = resppack.noisespectrumdata;
      % Create @respview objects
      view(ct,1) = resppack.noisespectrumview;
   end
end
set(view,'AxesGrid',this.AxesGrid)

% Return list of data-related properties of data object
dataprops = [data(1).findprop('Frequency'); ...
   data(1).findprop('Magnitude');...
   data(1).findprop('Phase');...
   data(1).findprop('Min');...
   data(1).findprop('Max');...
   data(1).findprop('Mean');...
   data(1).findprop('SD');...
   data(1).findprop('CommonFrequency')];


