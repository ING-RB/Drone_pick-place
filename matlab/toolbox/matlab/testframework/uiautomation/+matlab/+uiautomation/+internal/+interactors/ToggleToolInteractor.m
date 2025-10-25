classdef ToggleToolInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor, varargin)
            narginchk(1, 2);
            currentState = actor.Component.State;
            newState = true;
            
            if nargin == 2
                validateState(varargin{1});
                newState = varargin{1};
            end
            
            if isequal(currentState, newState)
                return;
            end
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uipress');
        end
        
        function uipress(actor, varargin)
            narginchk(1, 1);
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uipress');
        end
    end
    
end

function validateState(value)
validateattributes(value, {'logical'}, {'scalar'});
end