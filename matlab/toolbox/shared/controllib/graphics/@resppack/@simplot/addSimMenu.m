function mRoot = addSimMenu(this,menuType)
%ADDSIMMENU  Install @simplot-specific menus.

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.

AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu(menuType);  % search for specified menu (HOLD support)
if ~isempty(mRoot)
    return
end

switch menuType
    
    case 'show'
        % Show input signal
        mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
        'Label',getString(message('Controllib:plots:strShowInput')), ...
        'Tag','show',...
        'Callback',{@localToggleInputVis this});
        % Listeners
        L = handle.listener(this,this.findprop('Input'),...
        'PropertyPostSet',{@localTrackInputVis this mRoot});
        set(mRoot,'UserData',{L []})
        if ~isempty(this.Input)
            % Install listener to Input.Visible
            localTrackInputVis([],[],this,mRoot)
        end
        % Add right click menu for lsim GUI
    case 'lsimdata'
        mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
        'Label',getString(message('Controllib:plots:strInputDataLabel')), ...
        'Tag','lsimdata',...
        'Callback',{@localgui this 'lsimdata'},'separator','on');
        % Add right click menu for "initial" for of lsim GUI
    case 'lsiminit'
        mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
        'Label',getString(message('Controllib:plots:strInitialConditionLabel')), ...
        'Tag','lsiminit',...
        'Callback',{@localgui this 'lsiminit'});
end


%-------------------- Local Functions ---------------------------

function localgui(~,~, this, mode)

% open the lsim GUI
this.lsimgui(mode);

function localToggleInputVis(~,~,this)
% Toggles input visibility
Input = this.Input;
if isempty(Input)
    warndlg( getString(message('Controllib:plots:NoInputSignalDefined')),...
        getString(message('Controllib:plots:strShowInputWarning')),'modal')
else
    if strcmp(Input.Visible,'off')
        Input.Visible = 'on';
    else
        Input.Visible = 'off';
    end
end

function localTrackInputVis(~,~,this,mRoot)
% Install listener to track input visibility
L = get(mRoot,'UserData');
Input = this.Input;
if isempty(Input)
    L{2} = [];
    set(mRoot,'Checked','off')
else
    % Install listener to Input.Visible
    L{2} =  handle.listener(Input,Input.findprop('Visible'),...
    'PropertyPostSet',{@localSyncInputVis this mRoot});
    % Initialize check
    localSyncInputVis([],[],this,mRoot)
end
set(mRoot,'UserData',L)


function localSyncInputVis(~,~,this,mRoot)
% Update check status
set(mRoot,'Checked',this.Input.Visible)
