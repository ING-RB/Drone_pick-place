function Menu = findMenu(this,Tag)
%FINDMENU  Finds right-click menu with specified tag.

%  Author(s): James Owen
%  Copyright 1986-2009 The MathWorks, Inc.
Menu = handle(findobj(this.UIContextMenu,'Tag',Tag));
