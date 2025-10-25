function fontsContainer = editFont_Generic(this,tabLayout,rowIdx,columnIdx,data)
% editFont_Generic - Builds font container and adds listeners for Title,
% Axes and XYLabels

% Copyright 1986-2021 The MathWorks, Inc.

if isempty(this.FontsContainer) || ~isvalid(this.FontsContainer)
    fontsContainer = localBuildUI(data);
    this.FontsContainer = fontsContainer;
else
    fontsContainer = this.FontsContainer;
    unregisterUIListeners(fontsContainer);
    unregisterDataListeners(fontsContainer);
end
widget = getWidget(fontsContainer);
widget.Parent = tabLayout;
widget.Layout.Row = rowIdx;
widget.Layout.Column = columnIdx;
widget.Tag = 'Fonts';

if any(contains({data.FontType},{'Title'}))
    % Listeners to update data
    L = addlistener(fontsContainer,{'TitleFontSize','TitleFontWeight','TitleFontAngle'},...
            'PostSet',@(es,ed) localUpdateData(this.TitleStyle,fontsContainer,'Title'));
    registerUIListeners(fontsContainer,L,'UpdateTitleStyleData');
    
    props = [findprop(this.TitleStyle,'FontWeight');...
             findprop(this.TitleStyle,'FontSize');...
             findprop(this.TitleStyle,'FontAngle')];
    L = handle.listener(this.TitleStyle,props,'PropertyPostSet',...
        {@localUpdateUI this.TitleStyle fontsContainer 'Title'});
    registerDataListeners(fontsContainer,L,'UpdateTitleStyleUI');
end

if any(contains({data.FontType},{'Axes'}))
    % Listeners to update data
    L = addlistener(fontsContainer,{'AxesFontSize','AxesFontWeight','AxesFontAngle'},...
            'PostSet',@(es,ed) localUpdateData(this.AxesStyle,fontsContainer,'Axes'));
    registerUIListeners(fontsContainer,L,'UpdateAxesStyleData');
    
    props = [findprop(this.AxesStyle,'FontWeight');...
             findprop(this.AxesStyle,'FontSize');...
             findprop(this.AxesStyle,'FontAngle')];
    L = handle.listener(this.AxesStyle,props,'PropertyPostSet',...
        {@localUpdateUI this.AxesStyle fontsContainer 'Axes'});
    registerDataListeners(fontsContainer,L,'UpdateAxesStyleUI');
end

if any(contains({data.FontType},{'XYLabels'}))
    % UI Listeners to update data
    L = addlistener(fontsContainer,{'XYLabelsFontSize','XYLabelsFontWeight','XYLabelsFontAngle'},...
            'PostSet',@(es,ed) localUpdateData([this.XlabelStyle; this.YlabelStyle],...
            fontsContainer,'XYLabels'));
    registerUIListeners(fontsContainer,L,'UpdateXYLabelsStyleData');
    % Data listeners to update UI
    props = [findprop(this.XlabelStyle,'FontWeight');...
             findprop(this.XlabelStyle,'FontSize');...
             findprop(this.XlabelStyle,'FontAngle')];
    L = handle.listener(this.XlabelStyle,props,'PropertyPostSet',...
        {@localUpdateUI this.XlabelStyle fontsContainer 'XYLabels'});
    registerDataListeners(fontsContainer,L,'UpdateXLabelStyleUI');
    props = [findprop(this.YlabelStyle,'FontWeight');...
             findprop(this.YlabelStyle,'FontSize');...
             findprop(this.YlabelStyle,'FontAngle')];
    L = handle.listener(this.YlabelStyle,props,'PropertyPostSet',...
        {@localUpdateUI this.YlabelStyle fontsContainer 'XYLabels'});
    registerDataListeners(fontsContainer,L,'UpdateYLabelStyleUI');
end
end

%------------------ Local Functions ------------------------
function fontsContainer = localBuildUI(data)
fontTypes = {data.FontType};
fontsContainer = controllib.widget.internal.cstprefs.FontsContainer(fontTypes{:});
for k = 1:length(data)
    fontsContainer.([data(k).FontType,'FontSize']) = data(k).FontStyle(1).FontSize;
    fontsContainer.([data(k).FontType,'FontWeight']) = data(k).FontStyle(1).FontWeight;
    fontsContainer.([data(k).FontType,'FontAngle']) = data(k).FontStyle(1).FontAngle;
end
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

function localUpdateUI(~,~,fontStyle,fontsContainer,fontType)
disableUIListeners(fontsContainer);
fontsContainer.([fontType,'FontSize']) = fontStyle.FontSize;
fontsContainer.([fontType,'FontWeight']) = fontStyle.FontWeight;
fontsContainer.([fontType,'FontAngle']) = fontStyle.FontAngle;
enableUIListeners(fontsContainer);
end
