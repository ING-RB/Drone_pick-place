classdef ProgressBar < matlab.hwmgr.internal.hwsetup.ProgressBar
    %matlab.hwmgr.internal.hwsetup.appdesigner.ProgressBar is a class that
    %implements a progress bar using a combination of uiimage and uilabel.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.ProgressBar
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = private)
        %Height - Height set by the user. Peer always defaults to height of
        %6. User entered height is used primarily for read/write and has no
        %effect on the widget.
        Height
    end
    
    methods(Static)
        
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for ProgressBar
            %widget. Use ProgressIndicator UI Component.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.ui.control.internal.ProgressIndicator('Parent',...
                aParent);
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = ProgressBar(varargin)
            %ProgressBar - constructor
            
            obj@matlab.hwmgr.internal.hwsetup.ProgressBar(varargin{:});
            
            %This listener will invoke the destructor of the ProgressBar
            %when it's parent is destroyed.
            addlistener(obj.Parent, 'ObjectBeingDestroyed',...
                @obj.parentDeleteCallback);
        end
    end
    
    methods
        function setPosition(obj, position)
            %setPosition - sets position of ProgressBar. Height of
            %peer widget is locked to 6 and is read-only. Hence, override
            %and update other values, while keeping the height constant.
            
            obj.Height = position(4);
            position(4) = 6;
            
            setPosition@matlab.hwmgr.internal.hwsetup.WidgetBase(obj, position);
        end
        
        function position = getPosition(obj)
            %getPosition - gets position of ProgressBar. Read actual widget
            %position and update height as set by the user. Without the
            %override the height will always be 6.
            
           position = getPosition@matlab.hwmgr.internal.hwsetup.WidgetBase(obj);
           position(4) = obj.Height;
        end
    end
    
    methods(Access = protected)
        function setValue(obj, value)
            %setValue - set value to display the progress. This value will
            %be displayed only if Indeterminate is false.
            
            obj.Peer.Value = fix(value)/100;
            drawnow(); %immediately reflect the change
        end
        
        function setIndeterminate(obj, value)
            %setIndeterminate - set indeterminate state as true or false.
            
            obj.Peer.Indeterminate = logical(value);
            drawnow(); %immediately reflect the change
        end
        
        function value = getValue(obj)
            %getValue - get value of progress bar
            
            value = obj.Peer.Value * 100;
        end
        
        function value = getIndeterminate(obj)
            %getValue - get value of indeterminate state.
            
            value = logical(obj.Peer.Indeterminate);
        end
        
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete ProgressBar when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
end