function edit(this,PropEdit)
%EDIT  Configures Property Editor for response plots.

%   Copyright 1986-2020 The MathWorks, Inc.

AxGrid = this.AxesGrid;

% Labels
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strLabels')));
editLabels(AxGrid,tabLayout);

% Limits tab
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strLimits')));
tabLayout.RowHeight = {'fit','fit'};
tabLayout.ColumnWidth = {'1x'};
xLimContainer = AxGrid.editLimits('X',tabLayout,1,1);
yLimContainer = this.editYlims(tabLayout,2,1);
localCustomizeLimBox([],[],AxGrid,xLimContainer,yLimContainer); % @respplot customization

% Units
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strUnits')));
editUnits(this,tabLayout);


% Style
AxesStyle   = AxGrid.AxesStyle;
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strStyle')));
tabLayout.RowHeight = {'fit','fit','fit'};
tabLayout.ColumnWidth = {'1x'};
editGrid(AxGrid,tabLayout,1,1);
editFont(AxGrid,tabLayout,2,1);
editColors(AxesStyle,tabLayout,3,1);

% Characteristics
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strOptions')));
editChars(this,tabLayout);
 
% Set Title
PropEdit.Title = getString(message('Controllib:gui:strPropertyEditorLabel',this.AxesGrid.Title));

%------------------- Local Functions ------------------------------

function localCustomizeLimBox(eventsrc,~,AxGrid,xLimContainer,yLimContainer)
% Customizes X-Limits and Y-Limits tabs
AxSize = [AxGrid.Size 1 1];
% Input selector
% s = internal.getJavaCustomData(xLimContainer.GroupBox); % Java handles
XSelect = ~isempty(xLimContainer.getWidget.Parent);
if XSelect
    % Populate input selector
    if xLimContainer.NGroups > 1
        RCLabels = strrep(AxGrid.ColumnLabel,'From: ','');
        xLimContainer.GroupLabelText = getString(message('Controllib:gui:lblInput'));
        xLimContainer.GroupItems(2:end) = RCLabels;
    end
    %    LocalShowIOList(s.RCSelect,RCLabels(1:AxSize(4):end),AxSize(2))
end

% Output selector
% s = internal.getJavaCustomData(yLimContainer.GroupBox); % Java handles
YSelect = ~isempty(yLimContainer.getWidget.Parent);
if YSelect && yLimContainer.NGroups > 1
    yLimContainer.GroupLabelText = getString(message('Controllib:gui:lblOutput'));
    RCLabels = strrep(AxGrid.RowLabel,'To: ','');
    yLimContainer.GroupItems(2:end) = RCLabels(1:AxSize(3):end);AxSize(1);
%     LocalShowIOList(s.RCSelect,RCLabels(1:AxSize(3):end),AxSize(1))
end
%


%%%%%%%%%%%%%%%%%%%
% LocalShowIOList %
%%%%%%%%%%%%%%%%%%%
function LocalShowIOList(RCSelect,RCLabels,RCSize)
% Builds I/O lists for X- and Y-limit tabs
n = RCSelect.getSelectedIndex;
RCSelect.removeAllItems;
RCSelect.addItem(getString(message('Controllib:plots:strAll')));
for ct=1:length(RCLabels)
    RCSelect.addItem(sprintf('%s',RCLabels{ct}));
end
RCSelect.setSelectedIndex(n);

