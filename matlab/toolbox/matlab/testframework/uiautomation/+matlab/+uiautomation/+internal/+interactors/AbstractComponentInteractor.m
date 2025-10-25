classdef (Abstract) AbstractComponentInteractor < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Component
    end
    
    properties
        Dispatcher
    end
    
    methods
        
        function actor = AbstractComponentInteractor(H, dispatcher)
            actor.Component = H;
            actor.Dispatcher = dispatcher;
        end
        
        function uipress(actor, varargin)
            metaClass = metaclass(actor);
            methodList = metaClass.MethodList;
            chooseMethod = findobj(methodList,'Name','uichoose');
            if strcmp(chooseMethod.DefiningClass.Name,class(actor))
                actor.throwAlternative('press','choose');
            else
                actor.throwNotSupported('press');
            end
        end
        
        function uidoublepress(actor, varargin)
            actor.throwNotSupported('doublepress');
        end
        
        function uichoose(actor, varargin)
            actor.throwNotSupported('choose');
        end
        
        function uidrag(actor, varargin)
            actor.throwNotSupported('drag');
        end
        
        function uitype(actor, varargin)
            actor.throwNotSupported('type');
        end
        
        function uihover(actor, varargin)
            actor.throwNotSupported('hover');
        end
        
        function uiscroll(actor, varargin)
            actor.throwNotSupported('scroll');
        end
        
        function uicontextmenu(actor, varargin)
            actor.throwNotSupported('chooseContextMenu');
        end
    end
    
    methods(Access = private)
        
        function throwNotSupported(actor,gesture)
            error(message('MATLAB:uiautomation:Driver:GestureNotSupportedForClass', ...
                gesture, class(actor.Component)) );
        end

        function throwAlternative(actor, gesture, alternative)
            error(message('MATLAB:uiautomation:Driver:AlternativeGestureSupport', ...
                gesture, class(actor.Component), alternative));
        end
        
    end
    
end