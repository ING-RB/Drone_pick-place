function setgridstyle(this,Prop,Value)
%SETGRIDCOLOR  Updates style of grid lines and labels.

%   Copyright 1986-2014 The MathWorks, Inc.

GH = this.GridLines(ishghandle(this.GridLines));
switch Prop
case 'Color'
    gridLines = findobj(GH,'Type','line');
    gridText = findobj(GH,'Type','text');
    if Value == cstprefs.tbxprefs().GridColorFactoryValue
        arrayfun(@(h) matlab.graphics.internal.themes.specifyThemePropertyMappings(...
            h,'Color','--mw-backgroundColor-taskbarButton-active'),gridLines(:));
        arrayfun(@(h) matlab.graphics.internal.themes.specifyThemePropertyMappings(...
            h,'Color','--mw-backgroundColor-taskbarButton-hover'),gridText(:));
        set(allaxes(this),'GridColorMode','auto');
    else
        set(findobj(GH,'Type','line'),'Color',Value)
        set(findobj(GH,'Type','text'),'Color',0.5*Value)
        set(allaxes(this),'GridColor',Value)
    end
    
end