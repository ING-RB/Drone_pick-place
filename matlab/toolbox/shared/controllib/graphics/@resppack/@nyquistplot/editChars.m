function editChars(this,parent)
%EDITCHARS  Builds group box for editing Characteristics.

%   Copyright 1986-2020 The MathWorks, Inc.

gridLayout = uigridlayout(parent,[1 1]);
gridLayout.RowHeight = {'fit'};
gridLayout.Padding = 0;

localCreateConfRegContainer(this,gridLayout,1,1);

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

function localUpdateConfRegContainer(~,ed,confRegContainer)
Prefs = ed.NewValue;
confRegContainer.ConfidenceNumSD = Prefs.ConfidenceNumSD;
end

function localUpdateConfRegionData(this,~,ed)
this.Options.ConfidenceNumSD = ed.AffectedObject.ConfidenceNumSD;
end