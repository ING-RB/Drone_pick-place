function commentForImage = getDebugCommentForImage(fig)
envVar = getenv('IS_PUBLISHING');
if isempty(envVar)
    commentForImage = '';
else
    firstComment = getappdata(fig,'FirstPropertyChangeData');
    lastComment = getappdata(fig,'LastPropertyChangeData');
    firstPropChangeDataLabel = 'First Property Change Data';
    lastPropChangeDataLabel = 'Last Property Change Data';
        
    positionAndUnitsLabel = 'Figure Position (in pixels)';    
    figUnits = get(fig,'Units');
    figPosition = get(fig,'Position');
    if ~strcmp(figUnits,'pixels')
        figPosition = hgconvertunits(fig,figPosition,figUnits,'pixels',0);
    end
    positionAndUnitsStr = sprintf('  [%.f %.f %.f %.f]',...
        figPosition(1),figPosition(2),figPosition(3),figPosition(4));
    
    screenUnits = get(0,'Units');
    screenSizeAndUnitsLabel = sprintf('Screen Size (in %s)',screenUnits);
    screenSize = get(0,'ScreenSize');    
    screenSizeAndUnitsStr = sprintf('  [%.f %.f %.f %.f]',...
        screenSize(1),screenSize(2),screenSize(3),screenSize(4));
    
    pointerLocationLabel = 'Pointer Location';
    pointerLocation = get(0,'PointerLocation');    
    pointerLocationStr = sprintf('  [%.f %.f]',pointerLocation(1),pointerLocation(2));
    
    commentForImage = [ firstPropChangeDataLabel newline ...
                        firstComment newline ...
                        lastPropChangeDataLabel newline ...
                        lastComment newline ...
                        positionAndUnitsLabel newline ...
                        positionAndUnitsStr newline ...
                        screenSizeAndUnitsLabel newline ...
                        screenSizeAndUnitsStr newline ...
                        pointerLocationLabel newline ...
                        pointerLocationStr newline];
    if (isappdata(fig,'FirstPropertyChangeData') == 1)
        rmappdata(fig,'FirstPropertyChangeData');
    end
end
end