function viewmenufcn(hfig, cmd)
% This function is undocumented and will change in a future release

%VIEWMENUFCN Implements part of the figure view menu.
%  VIEWMENUFCN(CMD) invokes view menu command CMD on figure GCBF.
%  VIEWMENUFCN(H, CMD) invokes view menu command CMD on figure H.
%
%  CMD can be one of the following:
%
%    FigureToolbar
%    CameraToolbar

%  CMD Values For Internal Use Only:
%    ViewPost

%  Copyright 1984-2022 The MathWorks, Inc.

narginchk(1,2)

if nargin > 1
    cmd = convertStringsToChars(cmd);
end

if ischar(hfig)
    cmd = hfig;
    hfig = gcbf;
end

% DELETE THESE OLD MENU ENTRIES FROM FIGTOOLS.M ONCE TESTED
%   '&View',               'figMenuView',            'domymenu menubar initviewmenu',
%   '>&Figure Toolbar',    'figMenuFigureToolbar',   'domymenu(''menubar'',''toggletoolbar'',gcbf)',
%   '>&Camera Toolbar',    'figMenuCameraToolbar',   'cameratoolbar toggle',

switch cmd
    case 'ViewPost'
        LUpdateViewMenu(hfig);
    case 'FigureToolbar'
        domymenu('menubar','toggletoolbar',hfig)
    case 'CameraToolbar'
        cameratoolbar toggle
    case 'PloteditToolbar'
        plotedit(hfig,'plotedittoolbar','toggle');
  	case 'ObjectBrowser'
		openObjectBrowser;
    case 'PropertyInspector'
        % If the inspector window is already showing, then close the
        % inspector and exit out of plotedit mode
        matlab.graphics.internal.propertyinspector.propertyinspector('toggle');
end

%-----------------------------------------------------------------------%
function LUpdateViewMenu(fig)

offon = {'off','on'};

viewMenuItems = allchild(findobj(allchild(fig),'flat',...
    'Type','uimenu','Tag','figMenuView'));

tagList={
    'FigureToolBar',    'figMenuFigureToolbar'
    'CameraToolBar',    'figMenuCameraToolbar'
    'PlotEditToolBar',    'figMenuPloteditToolbar'
    };
plottoolsTagList={
    
    };

toolbarHandles=findall(fig,'type','uitoolbar');

for i=1:size(tagList,1)
    toolbarShowing = ~isempty(findall(toolbarHandles,...
        'tag',tagList{i,1},...
        'Visible','on'));
    menuHandle = findall(viewMenuItems,...
        'Type','uimenu',...
        'Tag',tagList{i,2});
    if ~isempty(menuHandle)
        set(menuHandle,...
            'Checked',offon{toolbarShowing+1});
    end
end

if ispref('plottools', 'isdesktop')
    rmpref('plottools', 'isdesktop');
end

isDocked = strcmp(get(fig,'WindowStyle'),'docked');

for i=1:size(plottoolsTagList,1)
    menuHandle = findall(viewMenuItems,...
        'Type','uimenu',...
        'Tag',plottoolsTagList{i,2});
    if ~isempty(menuHandle)
        if matlab.ui.internal.isJavaFigure(fig)
            % disable the warning when using the 'JavaFrame' property
            % this is a temporary solution
            oldJFWarning = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jf = matlab.ui.internal.JavaMigrationTools.suppressedJavaFrame(fig);
            warning(oldJFWarning.state, 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            groupName = jf.getGroupName;
            dt = jf.getDesktop;
            compName = get (menuHandle, 'Label');
            compShowing = dt.isClientShowing(compName, groupName) && isDocked;
            set(menuHandle,...
                'Checked',offon{compShowing+1});
        else
            set (menuHandle, 'Enable', 'off');
        end
    end
end

inspectorMenuHandle = findall(viewMenuItems,...
    'Type','uimenu',...
    'Tag','figMenuPropertyInspector');
if ~isempty(inspectorMenuHandle)
    % Check the checkbox if inspector window is showing
    if matlab.ui.internal.isJavaFigure(fig) && com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.isInspectorVisible
        set(inspectorMenuHandle,...
            'Checked','on');
    else
        set(inspectorMenuHandle, 'Checked', 'off');
    end
end

function openObjectBrowser
inspect(gca);
inspectorMap = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
inspectorManager = inspectorMap('/PropertyInspector');
inspectorManager.showObjectBrowser