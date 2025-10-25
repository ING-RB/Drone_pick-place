function editChars(this,parent)
%EDITCHARS  Builds group box for editing Characteristics.

%   Copyright 1986-2020 The MathWorks, Inc.

gridLayout = uigridlayout(parent,[2 1]);
gridLayout.RowHeight = {'fit','fit'};
gridLayout.Padding = 0;

opts = getoptions(this);

% Magnitude Response
if isempty(this.MagnitudeResponseContainer)
    magRespContainer = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();
else
    magRespContainer = this.MagnitudeResponseContainer;
end
% Initialize
magRespContainer.MinGainLimit.Enable = this.Options.MinGainLimit.Enable;
magRespContainer.MinGainLimit.MinGain = this.Options.MinGainLimit.MinGain;
% Build
widget = getWidget(magRespContainer);
widget.Parent = gridLayout;
widget.Layout.Row = 1;
widget.Tag = 'Magnitude Response';
this.MagnitudeResponseContainer = magRespContainer;

% Phase Response
if isempty(this.PhaseResponseContainer)
    phaseRespContainer = controllib.widget.internal.cstprefs.PhaseResponseContainer();
else
    phaseRespContainer = this.PhaseResponseContainer;
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
widget.Layout.Row = 2;
widget.Tag = 'Phase Response';
this.PhaseResponseContainer = phaseRespContainer;

% Add data listeners
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdateMagRespContainer magRespContainer});
registerDataListeners(magRespContainer,L,'UpdateUI');
L = handle.listener(this,findprop(this,'Options'),...
    'PropertyPostSet',{@localUpdatePhaseRespContainer phaseRespContainer});
registerDataListeners(phaseRespContainer,L,'UpdateUI');
L = handle.listener(this,findprop(this,'FrequencyUnits'),'PropertyPreSet',...
    {@localUpdateFreqUnits phaseRespContainer});
L2 = handle.listener(this.AxesGrid,findprop(this.AxesGrid,'XUnits'),'PropertyPreSet',...
    {@localUpdateMagPhaseUnits phaseRespContainer});
registerDataListeners(phaseRespContainer,[L; L2],'UpdateUnits');

% Add UI Listeners
L = addlistener(phaseRespContainer,{'UnwrapPhase','PhaseWrappingBranch','ComparePhase',},...
                'PostSet',@(es,ed) localUpdatePhaseRespData(this,ed));
registerUIListeners(phaseRespContainer,L,'Update Data');
L = addlistener(magRespContainer,'MinGainLimit','PostSet',...
                @(es,ed) localUpdateMagRespData(this,ed));
registerUIListeners(magRespContainer,L,'Update Data');

end

function localUpdateMagRespContainer(es,ed,magRespContainer)
Prefs = ed.NewValue;
magRespContainer.MinGainLimit.Enable = Prefs.MinGainLimit.Enable;
magRespContainer.MinGainLimit.MinGain = Prefs.MinGainLimit.MinGain;
end

function localUpdatePhaseRespContainer(es,ed,phaseRespContainer)
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

function localUpdateFreqUnits(es,ed,phaseRespContainer)
newUnits = ed.NewValue;
phaseRespContainer.FrequencyUnits = newUnits;
end

function localUpdateMagPhaseUnits(es,ed,phaseRespContainer)
newPhaseUnits = ed.NewValue;
phaseRespContainer.PhaseUnits = newPhaseUnits;
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
