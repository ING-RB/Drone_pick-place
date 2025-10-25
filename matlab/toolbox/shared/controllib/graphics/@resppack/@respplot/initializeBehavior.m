function initializeBehavior(this)
%initializeBehavior  Initializes the behavior for plot edit and propertyeditor
%   for the @respplot instance.

%  Author(s): C. Buhr
%   Copyright 1986-2016 The MathWorks, Inc.

hgaxes = getaxes(this.AxesGrid,'2D');

% Plot Edit Behavior
bh = hgbehaviorfactory('PlotEdit');
bh.EnableCopy = false;
bh.EnablePaste = false;
bh.EnableMove = false;
bh.EnableDelete = false;
hgaddbehavior(hgaxes(:),bh);

% Behavior for Property Browser
bh = hgbehaviorfactory('PlotTools');
bh.PropEditPanelObject = wrfc.PlotWrapper(this);
bh.PropEditPanelJavaClass= 'com.mathworks.toolbox.shared.controllib.propertyeditors.RespplotPropertyPanel';
hgaddbehavior(hgaxes(:),bh);


% Behavior for Live Editor Code Gen
[numrow,numcol] = size(hgaxes);
for rct = 1:numrow
    for cct = 1:numcol
        ax = hgaxes(rct,cct);
        bh = hggetbehavior(ax,'LiveEditorCodeGeneration');
        PlotType = this.Tag;
        bh.InteractionCodeFcn = @(arg1,arg2) localGenerateCode(ax,arg2,PlotType,rct,cct,hgaxes);
    end
end

end

function code = localGenerateCode(ax,pzrInfo,PlotType,rct,cct,hgaxes)
% ax - axes handle
% pzrInfo -  3x1 PZR interaction array

code = {};
[numrow,numcol] = size(hgaxes);
if ~isappdata(hgaxes(1),'MyLivePlot')
    for rct = 1:numrow
        l1(rct) = linkprop(hgaxes(rct,:),'YLim');
    end
    for cct = 1:numcol
        l1(numrow+cct) = linkprop(hgaxes(:,cct),'XLim');
    end
    setappdata(hgaxes(1),'MyLivePlot',l1)
end

if ishghandle(ax,'axes')
    if pzrInfo
        Info = localGetPlotTypeInfo(PlotType);

        code{end+1,1} = sprintf('h = %s; %% Use this command to return plot handle to programmatically customize the plot. ',Info.PlotCmd);
        code{end+1,1} = sprintf('p = getoptions(h);');
        temp = '';
        for ct =1:size(hgaxes,2)-1
            xlims = hgaxes(1,ct).XLim;
            temp = [temp, sprintf('[%g, %g];',xlims(1), xlims(2))];
        end
        xlims = hgaxes(1,size(hgaxes,2)).XLim;
        temp = [temp, sprintf('[%g, %g]',xlims(1), xlims(2))];
        code{end+1,1} = sprintf('p.XLim = {%s};',temp);
        temp = '';
        for ct =1:size(hgaxes,1)-1
            ylims = hgaxes(ct,1).YLim;
            temp = [temp, sprintf('[%g, %g];',ylims(1), ylims(2))];
        end
        ylims = hgaxes(size(hgaxes,1),1).YLim;
        temp = [temp, sprintf('[%g, %g]',ylims(1), ylims(2))];
        code{end+1,1} = sprintf('p.YLim = {%s};',temp);
        code{end+1,1} = sprintf('setoptions(h,p);');
%         code{end+1,1} = sprintf('%% Type "help %s" for more information.',Info.OptionsObject);
        code{end+1,1} = '';
    end
end

function Info = localGetPlotTypeInfo(PlotType)
    
PlotCmd = '';   
OptionsObject = '';
    
switch PlotType
    case 'bode'
        PlotCmd = 'bodeplot(...)';
        OptionsObject = 'bodeoptions';
    case 'impulse'
        PlotCmd = 'impulseplot(...)';
        OptionsObject = 'timeoptions';
    case 'initial'
        PlotCmd = 'initialplot(...)';
        OptionsObject = 'timeoptions';
    case 'iopzmap'
        PlotCmd = 'iopzplot(...)';
        OptionsObject = 'pzoptions';
    case 'hsv'
        PlotCmd = 'hsvplot(...)';
        OptionsObject = 'hsvoptions';
    case 'lsim'
        PlotCmd = 'lsimplot(...)';
        OptionsObject = 'timeoptions';
    case 'nichols'
        PlotCmd = 'nicholsplot';
        OptionsObject = 'nicholsoptions';
    case 'nyquist'
        PlotCmd = 'pznyquistplot';
        OptionsObject = 'nyquistoptions';
    case 'pzmap'
        PlotCmd = 'pzplot(...)';
        OptionsObject = 'pzoptions';
    case 'rlocus'
        PlotCmd = 'rlocusplot(...)';
        OptionsObject = 'pzoptions';
    case 'sigma'
        PlotCmd = 'sigmaplot(...)';
        OptionsObject = 'sigmaoptions';
    case 'step'
        PlotCmd = 'stepplot(...)';
        OptionsObject = 'timeoptions';
    case 'noisespectrum'
        PlotCmd = 'spectrum(...)';
        OptionsObject = 'spectrumoptions';
    case {'sectorplot'}
        PlotCmd = 'sectorplot(...)';
        OptionsObject = 'sectoroptions';
    case {'dirindex'}
        PlotCmd = 'passiveplot(...)';
        OptionsObject = 'directionalsectorplotoptions';
end

Info.PlotCmd = PlotCmd;
Info.OptionsObject = OptionsObject;
end

end

