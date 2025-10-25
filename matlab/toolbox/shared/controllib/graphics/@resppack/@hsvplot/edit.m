function edit(this,PropEdit)
%EDIT  Configures Property Editor for response plots.

%   Copyright 1986-2021 The MathWorks, Inc.

Axes = this.AxesGrid;

% Labels
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strLabels')));
editLabels(Axes,tabLayout);

% % Limits tab
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strLimits')));
tabLayout.RowHeight = {'fit','fit'};
tabLayout.ColumnWidth = {'1x'};
xLimContainer = Axes.editLimits('X',tabLayout,1,1);
yLimContainer = Axes.editLimits('Y',tabLayout,2,1);

% Style
AxesStyle   = Axes.AxesStyle;
tabLayout = findTabLayout(PropEdit,getString(message('Controllib:gui:strStyle')));
tabLayout.RowHeight = {'fit','fit','fit'};
tabLayout.ColumnWidth = {'1x'};
editGrid(Axes,tabLayout,1,1);
editFont(Axes,tabLayout,2,1);
editColors(AxesStyle,tabLayout,3,1);
