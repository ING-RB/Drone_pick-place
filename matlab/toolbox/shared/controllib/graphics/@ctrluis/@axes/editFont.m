function fontsContainer = editFont(this,tabLayout,rowIdx,columnIdx)
% Builds Font Tab for Property Editor

% Copyright 1986-2021 The MathWorks, Inc.
% Build FontData structure (targets generic editor to adequate style
% objects)
FontData = struct(...
   'FontType',{'Title','XYLabels','Axes'},...
   'FontStyle',{this.TitleStyle,...
      [this.XlabelStyle;this.YLabelStyle],...
      this.AxesStyle});

% Create group box
fontsContainer = this.editFont_Generic(tabLayout,rowIdx,columnIdx,FontData);