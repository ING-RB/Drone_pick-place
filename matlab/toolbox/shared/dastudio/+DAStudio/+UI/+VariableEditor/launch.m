function variableEditorObj = launch(varargin)
    varname = varargin{1};
    x = varargin{2};
    y = varargin{3};
    
    ssize = get(0,'ScreenSize');
    screenWidth = ssize(3);
    screenHeight = ssize(4);
    if x + 330 >= screenWidth
        x = screenWidth - 340; 
    end
    
    if screenHeight-y-230 <= 0
        y = 10;
    else
        y = screenHeight-y-230;
    end
    
    fig = uifigure('Position',[x y 330 220]);
    g = uigridlayout(fig,[1 1]);
    g.RowHeight = {'1x'};
    g.ColumnWidth = {'1x'};
    
    fig.Name = DAStudio.message('SLDD:sldd:UIVariableEditorWindowTitle');

    if nargin > 3
        workspace = varargin{4};
        % Base Workspaceedit toolbox/shared/controllib/graphics/+controllib/+widget/+internal/+variableeditor/VariableEditorPanel.m

        if (isequal(workspace, []))
            workspace = 'base';
        end
        variableEditorObj = matlab.ui.control.internal.VariableEditor('Variable', varname, 'Workspace', workspace, 'Parent', g, 'RowHeadersVisible', true, 'SummaryBarVisible', true, 'DataSelectable', 'on', 'DataSortable', 'on', 'DataTypeChangeable', 'on', 'DataEditable', true, 'ContextMenusVisible', true);
    else
        variableEditorObj = matlab.ui.control.internal.VariableEditor('Variable', varname, 'Parent', g, 'RowHeadersVisible', true, 'SummaryBarVisible', true, 'DataSelectable', 'on', 'DataSortable', 'on', 'DataTypeChangeable', 'on', 'DataEditable', true, 'ContextMenusVisible', true);
    end
end