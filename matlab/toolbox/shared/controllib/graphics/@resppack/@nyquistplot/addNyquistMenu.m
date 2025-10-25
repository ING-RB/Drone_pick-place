function mRoot = addNyquistMenu(this,menuType)
%ADDNYQUISTMENU  Install Nyquist-specific response plot menus.

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.

AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu(menuType);  % search for specified menu (HOLD support)
if ~isempty(mRoot)
   return
end

switch menuType
   
    case 'zoomcritical'
        % Zoom around critical point
        mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
            'Label',getString(message('Controllib:plots:strZoomOnNegative1')), ...
            'Tag','zoomcritical',...
            'Callback',{@LocalZoomCP this});
        
    case 'show'
        % Show menu
        mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
            'Label', getString(message('Controllib:plots:strShow')), ...
            'Tag','show');
        mSub = uimenu('Parent',mRoot, ...
            'Label', getString(message('Controllib:plots:strNegativeFrequencies')),...
            'Checked',this.ShowFullContour,...
            'Callback',{@LocalToggleContourVis this});
        L = handle.listener(this,findprop(this,'ShowFullContour'),...
            'PropertyPostSet',{@LocalSyncContourVis mSub});
        set(mSub,'UserData',L)
        
end


%-------------------- Local Functions ---------------------------

function LocalZoomCP(~,~,this)
% Zoom on critical point
zoomcp(this);


function LocalToggleContourVis(~,~,this)
% Toggles visibility of negative freqs
if strcmp(this.ShowFullContour,'on')
   this.ShowFullContour = 'off';
else
   this.ShowFullContour = 'on';
end
% Redraw
draw(this)


function LocalSyncContourVis(~,eventData,hMenu)
set(hMenu,'Checked',eventData.NewValue)
