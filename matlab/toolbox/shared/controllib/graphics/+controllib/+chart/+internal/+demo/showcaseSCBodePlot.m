function [h,v] = showcaseSCBodePlot(f)
arguments
    f = gcf
end

% Data
rng default
G = rss(3,2,2);
H = rss(3,2,2);

% Create chart
opts = bodeoptions('cstprefs');
h = controllib.chart.internal.demo.magphaseplot.SCBodePlot(Parent=f,Options=opts);

% The chart contains properties for labels, limits and row/column grouping
% and visibility. 

% Create response, responseView and set units
responseG = controllib.chart.internal.demo.magphaseplot.SCBodeResponse(G);
responseH = controllib.chart.internal.demo.magphaseplot.SCBodeResponse(H);

% Register responses
registerResponse(h,responseG);
registerResponse(h,responseH);

% Return axes view
v = qeGetView(h);

% The AxesView object can be used to modify magnitude and phase related
% properties.
end 