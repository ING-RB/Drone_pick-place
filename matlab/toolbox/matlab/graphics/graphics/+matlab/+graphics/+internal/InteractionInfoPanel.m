classdef InteractionInfoPanel

% This undocumented helper function is for internal use.
    
%  Copyright 2018 The MathWorks, Inc.

   methods(Static)
       function state = hasBeenOpened(varargin)
           mlock
           persistent hasOpened;
           
           % Only open the InfoPanel once per MATLAB session
           if nargin==0
               state = (~isempty(hasOpened) && hasOpened) || isdeployed;
           else
               hasOpened = varargin{1};
           end
               
       end
       
       function maybeShow(hObj)
           if ~matlab.ui.internal.isJavaFigure(ancestor(hObj,'figure'))
               return
           end
           if ~matlab.graphics.internal.InteractionInfoPanel.hasBeenOpened
               settingsObj = settings;
               showInteractionInfoBarSetting  = settingsObj.matlab.graphics.showinteractioninfobar;
               
               toShow = showInteractionInfoBarSetting.ActiveValue;
               if ~toShow && ~showInteractionInfoBarSetting.hasTemporaryValue
                   % If the InfoPanel setting is hidden with a
                   % non-temporary setting, make sure it was hidden in the
                   % current release. Temporary settings must always be 
                   % honored as they may be used to programmatically hide
                   % the InfoPanel (e.g. conditionalStopMgg.m)
                   releaseWhereInfoBarClosed = settingsObj.matlab.graphics.showinteractioninfobarreleaseset;
                   if ~strcmp(releaseWhereInfoBarClosed.ActiveValue,sprintf('R%s',version('-release')))
                       toShow = true;
                   end
               end

               if toShow
                   % Open InfoBar on Visible figures (so that the Live Editor is excluded)
                   % and figures which are not too small (where the Infobar occupies too
                   % much space)
                   fig = ancestor(hObj,'figure');
                   if ~isempty(fig) && strcmp(fig.Visible,'on') && strcmp(fig.HandleVisibility,'on') && ...
                       fig.Position(3)>386 && fig.Position(4)>276
                   bh = hggetbehavior(fig, 'Print','-peek');
                   % The InteractionInfoPanel uses a printing behavior
                   % object to prevent it being printed. If there is
                   % already a printing behavior object, so not show it to
                   % avoid any conflict
                       if isempty(bh) && matlab.ui.internal.hasDisplay
                           matlab.graphics.internal.InteractionInfoPanel.hasBeenOpened(true);
                           com.mathworks.hg.util.InfoPanel.addBannerPanel(ancestor(hObj,'figure'));
                       end
                   end
               end
           end
       end
   end
end
