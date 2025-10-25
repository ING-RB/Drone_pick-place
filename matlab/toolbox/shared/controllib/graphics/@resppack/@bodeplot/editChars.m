function editChars(this,parent)
%EDITCHARS  Builds group box for editing Characteristics.

%   Copyright 1986-2020 The MathWorks, Inc.

gridLayout = uigridlayout(parent,[3 1]);
gridLayout.RowHeight = {'fit','fit','fit'};
gridLayout.Padding = 0;

localCreateMagRespContainer(this,gridLayout,1,1);
localCreatePhaseRespContainer(this,gridLayout,2,1);
localCreateConfRegContainer(this,gridLayout,3,1);


end

function magRespContainer = localCreateMagRespContainer(this,gridLayout,rowIdx,~)
% Magnitude Response
if isempty(this.MagnitudeResponseContainer)
    magRespContainer = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();
else
    magRespContainer = this.MagnitudeResponseContainer;
    unregisterUIListeners(magRespContainer);
    unregisterDataListeners(magRespContainer);
end
% Initialize
magRespContainer.MinGainLimit.Enable = this.Options.MinGainLimit.Enable;
magRespContainer.MinGainLimit.MinGain = this.Options.MinGainLimit.MinGain;
% Build
widget = getWidget(magRespContainer);
widget.Parent = gridLayout;
widget.Layout.Row = rowIdx;
widget.Tag = 'Magnitude Response';
this.MagnitudeResponseContainer = magRespContainer;
% Add Data Listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdateMagRespContainer magRespContainer});
L2 = handle.listener(this.AxesGrid,findprop(this.AxesGrid,'YUnits'),'PropertyPostSet',...
    {@localUpdateMagUnits magRespContainer});
registerDataListeners(magRespContainer,[L; L2],'UpdateUI');
% Add UI Listeners
L = addlistener(magRespContainer,'MinGainLimit','PostSet',...
    @(es,ed) localUpdateMagRespData(this,ed));
registerUIListeners(magRespContainer,L,'Update Data');
end

function phaseRespContainer = localCreatePhaseRespContainer(this,gridLayout,rowIdx,~)
opts = getoptions(this);
% Phase Response
if isempty(this.PhaseResponseContainer)
    phaseRespContainer = controllib.widget.internal.cstprefs.PhaseResponseContainer();
else
    phaseRespContainer = this.PhaseResponseContainer;
    unregisterUIListeners(phaseRespContainer);
    unregisterDataListeners(phaseRespContainer);
end
% Initialize
phaseRespContainer.FrequencyUnits = opts.FreqUnits;
phaseRespContainer.PhaseUnits = opts.PhaseUnits;
if strcmp(opts.PhaseWrapping,'on')
    phaseRespContainer.UnwrapPhase = 'off';
else
    phaseRespContainer.UnwrapPhase = 'on';
end
if strcmp(opts.PhaseUnits,'deg')
    phaseRespContainer.PhaseWrappingBranch = rad2deg(this.Options.PhaseWrappingBranch);
else
    phaseRespContainer.PhaseWrappingBranch = this.Options.PhaseWrappingBranch;
end
phaseRespContainer.ComparePhase.Enable = this.Options.ComparePhase.Enable;
phaseRespContainer.ComparePhase.Freq = opts.PhaseMatchingFreq;
phaseRespContainer.ComparePhase.Phase = opts.PhaseMatchingValue;
% Build
widget = getWidget(phaseRespContainer);
widget.Parent = gridLayout;
widget.Layout.Row = rowIdx;
widget.Tag = 'Phase Response';
this.PhaseResponseContainer = phaseRespContainer;
% Add data listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdatePhaseRespContainer phaseRespContainer});
registerDataListeners(phaseRespContainer,L,'UpdateUI');
L = handle.listener(this.AxesGrid,findprop(this.AxesGrid,'XUnits'),'PropertyPostSet',...
    {@localUpdateFreqUnits phaseRespContainer});
L2 = handle.listener(this.AxesGrid,findprop(this.AxesGrid,'YUnits'),'PropertyPostSet',...
    {@localUpdatePhaseUnits phaseRespContainer});
registerDataListeners(phaseRespContainer,[L; L2],'UpdateUnits');
% Add UI Listeners
L = addlistener(phaseRespContainer,{'UnwrapPhase','PhaseWrappingBranch','ComparePhase',},...
    'PostSet',@(es,ed) localUpdatePhaseRespData(this,ed));
registerUIListeners(phaseRespContainer,L,'Update Data');
end

function confRegContainer = localCreateConfRegContainer(this,gridLayout,rowIdx,~)
% Confidence Region
if isempty(this.ConfidenceRegionContainer)
    confRegContainer = controllib.widget.internal.cstprefs.ConfidenceRegionContainer();
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
% Listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdateConfRegContainer confRegContainer});
registerDataListeners(confRegContainer,L,'UpdateUI');
L = addlistener(confRegContainer,'ConfidenceNumSD',...
    'PostSet',@(es,ed) localUpdateConfRegionData(this,es,ed));
registerUIListeners(confRegContainer,L,'Update Data');
end

function localUpdateMagRespContainer(~,ed,magRespContainer)
Prefs = ed.NewValue;
magRespContainer.MinGainLimit.Enable = Prefs.MinGainLimit.Enable;
magRespContainer.MinGainLimit.MinGain = Prefs.MinGainLimit.MinGain;
end

function localUpdatePhaseRespContainer(~,ed,phaseRespContainer)
Prefs = ed.NewValue;
phaseRespContainer.UnwrapPhase = Prefs.UnwrapPhase;
if strcmp(phaseRespContainer.PhaseUnits,'deg')
    phaseRespContainer.PhaseWrappingBranch = rad2deg(Prefs.PhaseWrappingBranch);
else
    phaseRespContainer.PhaseWrappingBranch = Prefs.PhaseWrappingBranch;
end
phaseRespContainer.ComparePhase.Enable = Prefs.ComparePhase.Enable;
phaseRespContainer.ComparePhase.Freq = Prefs.ComparePhase.Freq;
phaseRespContainer.ComparePhase.Phase = Prefs.ComparePhase.Phase;
end

function localUpdateFreqUnits(~,ed,phaseRespContainer)
newUnits = ed.NewValue;
phaseRespContainer.FrequencyUnits = newUnits;
end

function localUpdatePhaseUnits(~,ed,phaseRespContainer)
newPhaseUnits = ed.NewValue{2};
phaseRespContainer.PhaseUnits = newPhaseUnits;
end

function localUpdateMagUnits(~,ed,magRespContainer)
newMagUnits = ed.NewValue{1};
magRespContainer.MagnitudeUnits = newMagUnits;
end

function localUpdatePhaseRespData(this,ed)
this.Options.UnwrapPhase = ed.AffectedObject.UnwrapPhase;
if strcmp(ed.AffectedObject.PhaseUnits,'deg')
    this.Options.PhaseWrappingBranch = deg2rad(ed.AffectedObject.PhaseWrappingBranch);
else
    this.Options.PhaseWrappingBranch =ed.AffectedObject.PhaseWrappingBranch;
end
this.Options.ComparePhase.Enable = ed.AffectedObject.ComparePhase.Enable;
this.Options.ComparePhase.Freq = ed.AffectedObject.ComparePhase.Freq;
this.Options.ComparePhase.Phase = ed.AffectedObject.ComparePhase.Phase;
end

function localUpdateMagRespData(this,ed)
this.Options.MinGainLimit.Enable = ed.AffectedObject.MinGainLimit.Enable;
this.Options.MinGainLimit.MinGain = ed.AffectedObject.MinGainLimit.MinGain;
end

function localUpdateConfRegContainer(~,ed,confRegContainer)
Prefs = ed.NewValue;
confRegContainer.ConfidenceNumSD = Prefs.ConfidenceNumSD;
end

function localUpdateConfRegionData(this,~,ed)
this.Options.ConfidenceNumSD = ed.AffectedObject.ConfidenceNumSD;
end









