function varargout = daexplr(varargin)
%DAEXPLR Launches the Design Automation Model Explorer.
%   The Model Explorer is a unified explorer tool for Simulink,
%   Stateflow, SimMechanics, and related products.

%   Copyright 2004-2018 The MathWorks, Inc.

mlock;

%% parse input arguments
root     = slroot;
whattodo = [];
node     = [];

switch nargin
    case 0
        % use defaults

    case 1
         root   = varargin{1};
         
    case 2
        whattodo = varargin{1};
        node     = varargin{2};
        
    case 3
        root     = varargin{1};
        whattodo = varargin{2};
        node     = varargin{3};
        
    otherwise
        DAStudio.error('modelexplorer:message:MsgIncorrectArgCount');
end

%% error checking
if isempty(root) || ~(isa(root,'DAStudio.Object') || isa(root,'Simulink.DABaseObject')) || ~root.isHierarchical
    DAStudio.error('modelexplorer:message:MsgIncorrectRootType');
end

if ~isempty(whattodo) && ~ischar(whattodo)
    DAStudio.error('modelexplorer:message:MsgIncorrectArgType');
end

cosFlag = matlab.internal.feature('SLDataSourceViewMCOS');
if ~cosFlag && (~isempty(node) && ~(isnumeric(node) || isa(node, 'DAStudio.Object') || isa(node, 'Simulink.DABaseObject') || isa(node, 'DAStudio.WorkspaceNode')))
    DAStudio.error('modelexplorer:message:MsgIncorrectArgType');
end

%% open the Simulink & Stateflow Model Explorer
me        = [];
daRoot    = DAStudio.Root;
explorers = daRoot.find('-isa', 'DAStudio.Explorer');
for i=1:length(explorers)
    explorerRoot = explorers(i).getRoot;
    if root == explorerRoot
        me = explorers(i);
        break;
    end
end

if isempty(me)
    me = DAStudio.Explorer(root, 'DAStudio Model Explorer', false);
    configure(me);
end
me.delaySleepWake = 1;
me.show;

%% navigate to a node (if requested)
isStateflow = false;
if ~isempty(whattodo)
    if (strcmpi(whattodo,'view') || ...
        strcmpi(whattodo,'view_and_expand'))
        if ~ishandle(node)
            sfr = sfroot;
            node = sfr.find('id', node);
            if isempty(node)
                node = varargin{2};
            else
                isStateflow = true;
            end
        end
        % Check if this Stateflow object belongs to a library model.
        % Libraries are likely to be only loaded, not  open, so they will
        % not show up in Model Explorer and 'view' command below will fail
        % to find and highlight the node in the tree.
        if isStateflow && node.Machine.IsLibrary
            if bdIsLoaded(node.Machine.Path) && strcmp(get_param(node.Machine.Path, 'Shown'), 'off')
                open_system(node.Machine.Path);
                me.show;
            end
        end
        me.view(node);
    end
    
    if (strcmpi(whattodo,'view_and_expand'))
        me.expandTreeNode(node);
    end
end

if nargout == 1
    varargout{1} = me;
end


% Configure the ME instance to be the Simulink & Stateflow Model Explorer
function configure(me)

% add tree view toolbar actions
am = DAStudio.ActionManager;

% TODO: Add it as default actions now but once we have mechanism to sync actions in
% menus (w/o icons) to actions w/ icons, we will remove these default
% actions from .cpp.
maskAction = am.createDefaultAction(me, 'VIEW_TREESHOWMASKEDSUBSYSTEMS');
pathToIcon = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio','resources', 'showmaskmask_comp.png');
maskAction.icon = pathToIcon;
maskAction.toolTip = DAStudio.message('modelexplorer:DAS:ShowHideMasked');

linkAction = am.createDefaultAction(me, 'VIEW_TREESHOWLINKEDSUBSYSTEMS');
pathToIcon = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio','resources','showlinkmask_comp.png');
linkAction.icon = pathToIcon;
linkAction.toolTip = DAStudio.message('modelexplorer:DAS:ShowHideLinked');

me.addTreeAction(linkAction);
me.addTreeAction(maskAction);
me.showScopeOption(true)
% install views from preferences first then factory
vm = DAStudio.MEViewManager();
vm.install(me, true);
vm.customize;
action = am.createDefaultAction(me, 'VIEW_MANAGEVIEWS');
% action.callback = ['MEViewManager_action_cb(' num2str(action.id) ')'];
action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
addCallbackData(action, {'manageView', vm});
% Enable grouping in view manager
me.GroupingEnabled = true;
vm.load;
    
