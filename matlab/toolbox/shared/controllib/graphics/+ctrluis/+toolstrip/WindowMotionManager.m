classdef WindowMotionManager < handle
   %WINDOWMOTIONMANAGER Manages figure and line mouse motion callbacks.
   
   % Copyright 2013 The MathWorks, Inc
   
   properties
      Figure
      Target
      Widgets
      
      BDFcns = {};
      
      WBFcns = struct(...
         'WindowButtonUpFcn',    [],...
         'WindowButtonMotionFcn',[]);;
   end
   
   properties(GetAccess = public, SetAccess = protected)
      HostAx    %Axis that is tracking motion
      PT0       %Cursor point when motion started
      PT        %Cursor point during motion
   end
   
   methods
      function obj = WindowMotionManager(hFig)
         %WINDOWMOTIONMANAGER
         % hFig is figure handle.
         obj.Figure = hFig;
      end
      
      function target(this,action,target,widgets)
         %INIT
         % Input argument target must be a valid nonempty handle.   
         % Input arguments:
         %     action:  'install' or 'uninstall'
         %     target:  object that facilitates the callback routines
         %              wmMove, wmHover, wmStop and wmStart.
         %     widgets: an array of HG line handles
         
         % REVISIT: Use matlab.uitools.internal.uimodemanager to manage the
         %          mode 
         
         if strcmp(action,'install')
            this.Target  = target;
            this.Widgets = widgets;
            
            % Install new figure windowbutton functions and cache old ones
            hFig = this.Figure;
            activateuimode(hFig,''); %Disable any active uimodemanager
            flds = {'WindowButtonUpFcn','WindowButtonMotionFcn'};
            fcns = get(hFig,flds);
            this.WBFcns = cell2struct(fcns,flds,2);
            set(hFig,'WindowButtonUpFcn',     @(hSrc,hData) stop(this));
            set(hFig,'WindowButtonMotionFcn', @(hSrc,hData) move(this));
            
            if ishghandle(widgets)
               % Replace button down function for all the widgets
               this.BDFcns = get(widgets,{'ButtonDownFcn'});
               for ct = 1:numel(widgets)
                  set(widgets(ct),'ButtonDownFcn', @(hSrc,hData) start(this,widgets(ct)));
               end
            end
         else
            stop(this)
            
            % Restore figure windowbutton functions
            hFig = this.Figure;
            set(hFig,'WindowButtonUpFcn',     this.WBFcns.WindowButtonUpFcn);
            set(hFig,'WindowButtonMotionFcn', this.WBFcns.WindowButtonMotionFcn);
            
            % Restore button down function for all the widgets. Some
            % widgets may be part of the mode and so have already been
            % removed
            for ct = 1:numel(this.Widgets)
               if ishghandle(this.Widgets(ct))
                  set(this.Widgets(ct),'ButtonDownFcn', this.BDFcns{ct})
               end
            end
            
            % Clean up target
            this.Target  = [];
            this.Widgets = [];
         end
      end
      function resetPT(this,pt0)
         %RESETPT
         %
         
         this.PT0 = pt0;
         this.PT  = pt0;
      end
   end
   
   methods(Access = protected)
      function start(this,widget)
         %START
         %
         
         if isempty(this.Target) %&& ~isempty(this.HostAx)
            %Nothing to do
            return
         end
         
         % Initialize WMM properties
         hostAx      = ancestor(widget,'axes');
         cPt         = get(hostAx,'CurrentPoint');
         this.PT0    = cPt;
         this.PT     = this.PT0;
         this.HostAx = hostAx;
         
         %Call target start-specific code
         wmStart(this.Target,widget)
      end
      
      function move(this)
         %MOVE
         %
         if isempty(this.Target)
            % Nothing to do
            return
         elseif isempty(this.HostAx)
            % hover
            wmHover(this.Target)
         else
            % move the clicked object
            %Update cursor position data
            cPt = get(this.HostAx,'CurrentPoint');
            this.PT = cPt;
            
            %Call target move-specific code
            wmMove(this.Target)
         end         
      end
      
      function stop(this)
         %STOP
         %
         
         if isempty(this.Target) || isempty(this.HostAx)
            %Nothing to do
            return
         end
         
         %Clear HostAx tracking cursor movement
         this.HostAx = [];
         
         %Call target stop-specific code
         wmStop(this.Target)
      end
   end
end