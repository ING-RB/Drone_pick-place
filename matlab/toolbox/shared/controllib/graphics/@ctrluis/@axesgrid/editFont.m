function fontsContainer = editFont(this,tabLayout,rowIdx,columnIdx)
% Builds Font Tab for Property Editor

% Copyright 1986-2021 The MathWorks, Inc.

FontData = struct(...
    'FontType',{'Title','XYLabels','Axes','IOLabels'},...
    'FontStyle',{this.TitleStyle,...
      [this.XlabelStyle;this.YLabelStyle],...
      this.AxesStyle,...
      [this.ColumnLabelStyle;this.RowLabelStyle]});

% Create container
fontsContainer = this.editFont_Generic(tabLayout,rowIdx,columnIdx,FontData);

% Add listeners for RowLabel and ColumnLabel
% UI Listeners to update data
L = addlistener(fontsContainer,{'IOLabelsFontSize','IOLabelsFontWeight','IOLabelsFontAngle'},...
    'PostSet',@(es,ed) localUpdateData([this.RowlabelStyle; this.ColumnlabelStyle],...
    fontsContainer,'IOLabels'));
registerUIListeners(fontsContainer,L,'UpdateIOLabelsStyleData');
% Data listeners to update UI
props = [findprop(this.RowlabelStyle,'FontWeight');...
    findprop(this.RowlabelStyle,'FontSize');...
    findprop(this.RowlabelStyle,'FontAngle')];
L = handle.listener(this.RowLabelStyle,props,'PropertyPostSet',...
    {@localUpdateUI this.RowlabelStyle fontsContainer 'IOLabels'});
registerDataListeners(fontsContainer,L,'UpdateXLabelStyleUI');
props = [findprop(this.ColumnlabelStyle,'FontWeight');...
    findprop(this.ColumnlabelStyle,'FontSize');...
    findprop(this.ColumnlabelStyle,'FontAngle')];
L = handle.listener(this.ColumnlabelStyle,props,'PropertyPostSet',...
    {@localUpdateUI this.ColumnlabelStyle fontsContainer 'IOLabels'});
registerDataListeners(fontsContainer,L,'UpdateYLabelStyleUI');

end

function localUpdateData(fontStyle,fontsContainer,fontType)
disableDataListeners(fontsContainer);
for k = 1:length(fontStyle)
    fontStyle(k).FontSize = fontsContainer.([fontType,'FontSize']);
    fontStyle(k).FontWeight = fontsContainer.([fontType,'FontWeight']);
    fontStyle(k).FontAngle = fontsContainer.([fontType,'FontAngle']);
end
enableDataListeners(fontsContainer);
end

function localUpdateUI(es,ed,fontStyle,fontsContainer,fontType)
disableUIListeners(fontsContainer);
fontsContainer.([fontType,'FontSize']) = fontStyle.FontSize;
fontsContainer.([fontType,'FontWeight']) = fontStyle.FontWeight;
fontsContainer.([fontType,'FontAngle']) = fontStyle.FontAngle;
enableUIListeners(fontsContainer);
end
