function open(this, varargin)
%OPEN - Open contextmenu at location within UI figure
%
%   OPEN(contextmenu, X,Y) - open contextmenu at specified (X,Y) coordinates
%   within a UI figure.  The coordinates are measured in pixels from the
%   lower-left corner of the figure.
%
%   OPEN(contextmenu, [X Y]) - open contextmenu at specified pixel coordinates [X Y].
%
%   Example 1: Open contextmenu in uifigure using (X,Y) coordinates
%      fig = uifigure;
%      cm = uicontextmenu(fig);
%      m = uimenu(cm,'Text','Menu1');
%      open(cm, 250, 250);
%
%   Example 2: Open contextmenu in uifigure using pixel coordinates [X Y]
%      fig = uifigure;
%      cm = uicontextmenu(fig);
%      m = uimenu(cm,'Text','Menu1');
%      open(cm, [250 250]);


%   Copyright 2019 The MathWorks, Inc.

    if ~(matlab.ui.internal.isUIFigure(this.Parent))
        % warn when open is called in java figures
        warning(message('MATLAB:ui:components:ContextMenuOpenUnSupported'));
    else
        narginchk(2, 3);
        try
            % set Position property to given input value
            if length(varargin) == 1
                this.Position = varargin{1};
            elseif length(varargin) == 2
                this.Position = [varargin{1:2}];
            end
            % set Visible property to 'on'
            this.Visible = 'on';
        catch ME %#ok<NASGU>
            % throw error when invalid open position is specified
            error(message('MATLAB:ui:components:ContextMenuInvalidOpenLocation'));
        end
    end
end
