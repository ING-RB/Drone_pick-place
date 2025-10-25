classdef Panel < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.Container
    %matlab.hwmgr.internal.hwsetup.Panel is a class that defines a HW
    %   Setup panel
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   p.Position = [20 20 200 200];
    %   p.Title = 'MyPanel';
    %   p.TitlePosition = 'centertop';
    %   p.show();
    
    %   Copyright 2016-2020 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        Title % Panel title
        TitlePosition % Location of the panel title ex: 'centertop'
        BorderType % Type of panel border ex: 'line', 'none'
        
        % Inherited Properties
        % Visible
        % Tag
        % Position
    end
    
    properties(SetAccess = protected, GetAccess = protected)
        % Inherited Properties
        % Peer
    end
    
    properties(SetAccess = immutable, GetAccess = protected)
        % Inherited Properties
        % Parent
    end
    
    properties(SetAccess = protected, GetAccess = private)
        % Inherited Properties
        % DeleteFcn
    end
    
    
    methods(Access = protected)
        function obj = Panel(varargin)
            %Panel- constructor to set defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            
            %if parent is a grid
            if ~isequal(class(obj.Parent),...
                    'matlab.hwmgr.internal.hwsetup.appdesigner.Grid')
                [pW, pH] = obj.getParentSize();
                obj.Position = [pW*0.25 pH*0.25 pW*0.5 pH*0.5];
            end
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            obj.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
            obj.Title = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.PanelTitle;
            obj.BorderType = 'line';
            obj.TitlePosition = 'centertop';
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    %% Property setter and getter
    methods
        %Todo: Technology implementation for border can be removed once 
        %g2253923 is addressed.
        function title = get.BorderType(obj)
            %get.BorderType- get border type.
            
            title = getBorderType(obj);
        end
        
        function set.BorderType(obj, borderType)
            %set.BorderType- set border type.
            
            setBorderType(obj, borderType)
        end
        
        function title = get.Title(obj)
            title = get(obj.Peer, 'Title');
        end
        
        function set.Title(obj, title)
            validateattributes(title, {'char', 'string'}, {});
            set(obj.Peer, 'Title', title);
        end
        
        function set.TitlePosition(obj, titlePos)
            setTitlePosition(obj, titlePos);
        end
        
        function titlePos = get.TitlePosition(obj)
            titlePos = get(obj.Peer, 'TitlePosition');
        end
    end
    
    methods(Access = ?matlab.hwmgr.internal.hwsetup.TemplateBase)
        function disable(obj)
            set(findall(obj.Peer, '-property', 'enable'), 'enable', 'off')
        end
        
        function enable(obj)
            try
                set(findall(obj.Peer, '-property', 'enable'), 'enable', 'on')
            catch
                % During renable of screens on cleanup, if found that the
                % parent HW setup window is terminated then throw an error.
                % Instead of 'Invalid or deleted object.' error we will now
                % throw 'Hardware Setup Terminated, please try again.' in
                % command window.
                error(message('hwsetup:widget:HWSetupTerminated'));
            end
        end
    end
    
    methods(Abstract, Access = protected)
        %setTitlePosition- Technology specific implementation for setting
        %title position.
        setTitlePosition(obj, titlePos);
        
        %setBorderType- Technology specific implementation for setting
        %border type.
        setBorderType(obj, borderType);
        
        %getBorderType- Technology specific implementation for getting 
        %border type.
        title = getBorderType(obj);
    end
end