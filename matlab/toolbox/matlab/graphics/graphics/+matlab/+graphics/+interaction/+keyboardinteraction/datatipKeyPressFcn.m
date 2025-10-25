function keyconsumed = datatipKeyPressFcn(ax, evd)

% Copyright 2022 The MathWorks, Inc.

keypressed = evd.Key;

% Parse key press
movedir = [];
switch evd.Key
    case 'leftarrow'
        movedir = 'left';
        keyconsumed = true;
    case 'rightarrow'
        movedir = 'right';
        keyconsumed = true;
    case 'uparrow'
        movedir = 'up';
        keyconsumed = true;
    case 'downarrow'
        movedir = 'down';
        keyconsumed = true;
     otherwise
        keyconsumed = false;
end

% Move/delete datacursor
dm = datacursormode(ancestor(ax,'figure'),'-nocontextmenu');
hCursor = dm.CurrentCursor;
if ~isempty(hCursor) && isvalid(hCursor)
    if ~isempty(movedir)
        hCursor.increment(movedir);
        keyconsumed = true;
    elseif strcmp(keypressed,'delete') || strcmp(keypressed,'backspace')
        dm.removeDataCursor(hCursor);
        keyconsumed = true;
    end
end
