function createPlot(this)
%CREATEPLOT
%

% Copyright 2013-2014 The MathWorks, Inc.

%Get time plot from figure and create a bodemag plot above it
hPlot = getPlot(this.Figure);
this.Plot = lCreateBodeMag(hPlot,this.Figure,this.Widgets.PlotVertGap);

%Set plot visible
set(this.Plot,'Visible','on')
end

function nPlot = lCreateBodeMag(hPlot,Fig,vGap)
%Helper to create a bode magnitude plot

%Create plot
hAx  = axes('Parent',Fig.Figure,'Visible','off');
opts = plotopts.IOFrequencyPlotOptions('cstprefs');
opts.PhaseVisible = 'off';
dSrc = getWorkingData(Fig);
iName = getInputName(dSrc);
oName = getOutputName(dSrc);
nPlot = iodataplot(hAx,'frequency',...
    iName, oName, ...
    opts, cstprefs.tbxprefs);

%Position the plot
pos = hPlot.AxesGrid.Position; %Plot is already sized in configurePlot method
nPlot.AxesGrid.Position = pos +[0 pos(4)+2*vGap 0 0];
nPlot.AxesGrid.Title    = hPlot.AxesGrid.Title;

%Add a waveform(s) to the plot
for ct=1:numel(hPlot.Wave)
    src = hPlot.Wave(ct).DataSrc;
    if src.IOData == dSrc
        wf = nPlot.addresponse(src);
        wf.DataFcn = {'ctrluis.toolstrip.dataprocessing.absFilterMode.updateWaveForm', wf};
        DefinedCharacteristics = getCharacteristics(src,'frequency');
        wf.setCharacteristics(DefinedCharacteristics);
        initsysresp(wf,'bode',nPlot.Options)
    
        %Refresh the response
        wf.draw
    end
end

% Right-click menus
iodataplotmenu(nPlot, 'frequency');
end