%UICONTEXTMENU Create context menu component
%
% cm = uicontextmenu creates a context menu in the current figure and 
% returns the ContextMenu object as cm. If a figure does not exist, then
% MATLAB calls the figure function to create one.
%
% cm = uicontextmenu(parent) creates a context menu in the specified parent
% figure. The parent container can be a figure created with either the
% uifigure or figure function. Specifying a parent alone does not make the
% context menu accessible in the app. You must also take these steps:
%
% - Assign the context menu to a UI component using the ContextMenu property
%   of the component.
% - The component must be in the same figure as the context menu.
% - Create at least one child Menu object within the context menu.
%
% cm = uicontextmenu(____,Name,Value) creates a context menu with property
% values specified using one or more name-value pair arguments. Use this
% syntax with any of the input argument combinations in the previous syntaxes.
%
% Example 1: Create and assign a context menu to a UI figure
%   fig = uifigure;
%   cm = uicontextmenu(fig);
%   m1 = uimenu(cm,'Text','Menu1');
%   m2 = uimenu(cm,'Text','Menu2');
%   fig.ContextMenu = cm;
%
% Example 2: Create a context menu with submenus and assign it to a panel
%   f = figure;
%   cm = uicontextmenu(f);
%   m1 = uimenu(cm,'Text','Menu1');
%   m2 = uimenu(cm,'Text','Menu2');
%   m3 = uimenu(m1,'Text','Sub-Menu1');
%   p = uipanel(f);
%   p.ContextMenu = cm;
%
%   See also UIMENU, UIFIGURE.

%   Copyright 1984-2019 The MathWorks, Inc. 
%   Built-in function.
