classdef ModeManager < handle
    %
    
    % Copyright 2013 The MathWorks, Inc
    
    properties(GetAccess = public, SetAccess = protected)
        Modes = [];
    end
    
    properties(GetAccess = protected, SetAccess = protected)
        ModeHandler = @ctrluis.toolstrip.ModeManager.ExclusiveModeHandler;
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        ModeChanged
    end
    
    methods(Access = public)
        function registerMode(this,mode)
            %REGISTERMODE
            %
            
            idx = findMode(this,mode);
            if idx
                error(message('Controllib:general:UnexpectedError','Already have this mode registered'))
            else
                this.Modes = vertcat(this.Modes,mode);
                setModeManager(mode,this)
            end
        end
        function unregisterMode(this,mode)
            %UNREGISTER
            %
            
            idx = findMode(this,mode);
            if idx
                %Disable mode before unregistering
                this.Modes(idx).Enabled = false;
                this.Modes(idx) = [];
            else
                error(message('Controllib:general:UnexpectedError','No mode registered'))
            end
        end
        function tabs = getModeTabs(this)
            %GETMODETABS
            %
            activeModes = getActiveMode(this);
            if isempty(activeModes)
                tabs = [];
            else
                tabs = getModeTab(activeModes(1));
                for ct=2:numel(activeModes)
                    tabs = vertcat(tabs,getModeTab(activeModes(ct)));
                end
            end
        end
        function mode = getActiveMode(this)
            %GETACTIVEMODE
            %
            
            if isempty(this.Modes)
                mode = [];
            else
                idx = [this.Modes.Enabled];
                mode = this.Modes(idx);
            end
        end
        function setModeHandler(this,modehandler)
            %SETMODEHANDLER
            %
            this.ModeHandler = modehandler;
        end
    end
    
    methods(Hidden = true, Access = public)
        function setModeState(this,mode,enabled)
            %MANAGEMODESTATES
            %
            
            notify(this,'ModeChanged', ctrluis.toolstrip.ModeChangedEventData('PreModeChanged'))
            this.ModeHandler(this.Modes,mode,enabled)
            notify(this,'ModeChanged', ctrluis.toolstrip.ModeChangedEventData('PostModeChanged'))
        end
    end
    
    methods(Access = protected)
        function idx = findMode(this,mode)
            %FINDMODE
            %
            
            idx = 0;
            ct = 1;
            while idx < 1 && ct <= numel(this.Modes)
                if isequal(this.Modes(ct),mode);
                    idx = ct;
                end
                ct = ct + 1;
            end
        end
    end
    
    methods(Static = true, Access = protected)
        function ExclusiveModeHandler(modes, mode, enabled)
            %EXCLUSIVEMODEHANDLER
            %
            
            %Modes must be mutually exclusive. First disable active modes,
            %then set the mode
            if enabled
                e = [modes.Enabled];
                activeModes = modes(e);
                for ct=1:numel(activeModes)
                    setEnabled(activeModes(ct),false,true);
                end
            end
            setEnabled(mode,enabled,true);
        end
    end
end