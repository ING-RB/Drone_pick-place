classdef AppStateChangeEventAggregator < handle
% This class is undocumented and will change in a future release

% APPSTATECHANGEEVENTAGGREGATOR Object that will fire an AppStateChanged event whenever state may have changed in an app.
%
% This class is intended for use by Live Editor embedded apps to fire an event
% letting the Live Editor know when it needs to regenerate code because the end
% user has changed the state of the app.

% Copyright 2018-2022 The MathWorks, Inc.
    
    properties(Access=private)
        Listeners = event.listener.empty;  % Cache of the listeners used by this aggregator
    end

    events
        AppStateChanged  % Fires whenever any ValueChanged, ButtonPushed, or SelectionChanged event fires within the attached Figure
    end

    methods
        function attach(this, fig)
        % Attach the aggregator to a given Figure and begin firing AppStateChanged
        % events when changes happen in that Figure.
            comps = findall(fig);
            for comp = comps'
                % Attach to visible events
                if find(strcmp(events(comp), 'ValueChanged'))
                    attachListener(this, comp, 'ValueChanged');
                end
                if find(strcmp(events(comp), 'ButtonPushed'))
                    attachListener(this, comp, 'ButtonPushed');
                end
                if find(strcmp(events(comp), 'ImageClicked'))
                    attachListener(this, comp, 'ImageClicked');
                end

                % g2822757 - If the component is a TabGroup, do not add the
                % event listener
                if ~isa(comp, 'matlab.ui.container.TabGroup')
                    % Attach to hidden events
                    try
                        attachListener(this, comp, 'SelectionChanged');
                    catch ex
                    end
                end
            end
        end
        
        function delete(this)
        % Destroys the given aggregator.
            for i = 1:length(this.Listeners)
                delete(this.Listeners(i));
            end
        end
    end
       
    methods(Access=private)
        function attachListener(this, comp, eventName)
        % Helper function to attach a listener to an event on a given component.
        % The AppStateChanged event will hencefore fire after the given component/event
        % fires.
            nListeners = length(this.Listeners);
            this.Listeners(nListeners+1) = addlistener(comp, eventName, @(o,e)this.fireEvent);
        end
        
        function fireEvent(this,~,~)
        % Helper function to fire the AppStateChanged event.
        % Fires on the next flush of the drawnow queue.
            matlab.graphics.internal.drawnow.callback(@()this.notify('AppStateChanged'));
        end
    end

end
