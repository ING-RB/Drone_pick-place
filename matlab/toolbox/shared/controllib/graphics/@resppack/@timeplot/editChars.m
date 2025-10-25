function editChars(this,parent)
%EDITCHARS  Builds group box for editing Characteristics.

%   Copyright 1986-2020 The MathWorks, Inc.

gridLayout = uigridlayout(parent,[2 1]);
gridLayout.RowHeight = {'fit','fit'};
if strcmpi(this.Tag,'step') || strcmpi(this.Tag,'impulse')
    localCreateTimeRespContainer(this,gridLayout,1,1);
    localCreateConfRegContainer(this,gridLayout,2,1);
else
    gridLayout = uigridlayout(parent,[1 1]);
    gridLayout.RowHeight = {'fit'};
    gridLayout.Layout.Row = 1;
    this.NoOptionsLabel = uilabel(gridLayout,'Text',getString(message('Controllib:gui:strNoOptionsForSelectedPlot')));
end
end

function timeRespContainer = localCreateTimeRespContainer(this,gridLayout,rowIdx,~)
if isempty(this.TimeResponseContainer)
    if strcmpi(this.Tag,'step')
        showRiseTime = true;
    else
        showRiseTime = false;
    end
    timeRespContainer = controllib.widget.internal.cstprefs.TimeResponseContainer(...
                            'ShowRiseTime',showRiseTime);
else
    timeRespContainer = this.TimeResponseContainer;
    unregisterDataListeners(timeRespContainer);
    unregisterUIListeners(timeRespContainer);
end
% Build
widget = getWidget(timeRespContainer);
widget.Parent = gridLayout;
widget.Layout.Row = rowIdx;
widget.Tag = 'Time Response';
% Listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdateTimeRespContainer timeRespContainer this});
registerDataListeners(timeRespContainer,L,'UpdateUI');
L = addlistener(timeRespContainer,{'SettlingTimeThreshold','RiseTimeLimits'},...
                    'PostSet',@(es,ed) localUpdateTimeRespData(this,es,ed));
registerUIListeners(timeRespContainer,L,'Update Data');
this.TimeResponseContainer = timeRespContainer;
end

function localUpdateTimeRespContainer(es,ed,timeRespContainer,this)
Options = ed.NewValue;
timeRespContainer.SettlingTimeThreshold = Options.SettlingTimeThreshold;
if strcmpi(this.Tag,'step')
    timeRespContainer.RiseTimeLimits = Options.RiseTimeLimits;
end
end

function localUpdateTimeRespData(this,es,ed)
this.Options.(es.Name) = ed.AffectedObject.(es.Name);
end

function confRegContainer = localCreateConfRegContainer(this,gridLayout,rowIdx,~)
% Confidence Region
if isempty(this.ConfidenceRegionContainer)
    if strcmpi(this.Tag,'step')
        showZeroMeanInterval = false;
    else
        showZeroMeanInterval = true;
    end
    confRegContainer = controllib.widget.internal.cstprefs.ConfidenceRegionContainer(...
                            'ShowZeroMeanCheckbox',showZeroMeanInterval);
else
    confRegContainer = this.ConfidenceRegionContainer;
    unregisterDataListeners(confRegContainer);
    unregisterUIListeners(confRegContainer);
end
% Build
widget = getWidget(confRegContainer);
widget.Parent = gridLayout;
widget.Layout.Row = rowIdx;
widget.Tag = 'Confidence Region';
this.ConfidenceRegionContainer = confRegContainer;
% Initialize
confRegContainer.ConfidenceNumSD = this.Options.ConfidenceNumSD;
if isfield(this.Options,'ZeroMeanInterval')
    confRegContainer.ZeroMeanInterval = this.Options.ZeroMeanInterval;
else
    this.Options.ZeroMeanInterval = true;
    confRegContainer.ZeroMeanInterval = true;
end
% Listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdateConfRegContainer confRegContainer this});
registerDataListeners(confRegContainer,L,'UpdateUI');
L = addlistener(confRegContainer,{'ConfidenceNumSD','ZeroMeanInterval'},...
    'PostSet',@(es,ed) localUpdateConfRegionData(this,es,ed));
registerUIListeners(confRegContainer,L,'Update Data');
end

function localUpdateConfRegContainer(~,ed,confRegContainer,this)
Prefs = ed.NewValue;
confRegContainer.ConfidenceNumSD = Prefs.ConfidenceNumSD;
if ~strcmpi(this.Tag,'step')
    confRegContainer.ZeroMeanInterval = Prefs.ZeroMeanInterval;
end
end

function localUpdateConfRegionData(this,es,ed)
this.Options.(es.Name)= ed.AffectedObject.(es.Name);
end
