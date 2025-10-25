function markFigure(objs)
%markFigure Mark an editor figure as changed

%   Copyright 2015-2020 The MathWorks, Inc.

for obj = objs(:)'
    if isgraphics(obj)
        fig = ancestor(obj,'figure');
        if ~isempty(fig) && isprop(fig, 'EDITOR_APPDATA')
            % toggling Color to mark the figure as changed
            color = get(fig,'Color');
            if isnumeric(color)
                newcolor = 1-color;
                if isequal(color, newcolor)
                    newcolor = [0 0 0];
                end
            else % Figure color can be 'none'
                newcolor = [0 0 0];
            end
            set(fig,'Color_I',newcolor);
            set(fig,'Color_I',color);
        end
    end
end