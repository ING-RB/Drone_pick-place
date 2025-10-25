classdef Subscriber < handle
%SUBSCRIBER - Superclass for Subscriber classes.

% Subscriber classes are the ones that are interested in subscribing to
% a certain property published by one or more publishers. Any module
% that wishes to be a subscriber should inherit from the 'Subscriber'
% class and implement the abstract method
% 'subscribeToMediatorProperties'. In this method, you will mention the
% publisher property that you want to subscribe to.
%
% E.g. Example code for subscribing to a particular property:
% obj.subscribe('PublisherPropertyOfYourChoice',...
% @(src, event)obj.takeAction(event.AffectedObject.PublisherPropertyOfYourChoice));

% Copyright 2016-2024 The MathWorks, Inc.

    properties (Access = private)
        Mediator (1,1) matlabshared.mediator.internal.Mediator

        SubscribeListener
        UnsubscribeListener

        PropEventListenerArray = event.proplistener.empty
    end

    methods (Abstract)
        % By implementing this method in the derived class, those classes
        % (subscribers) can listen to the properties of their
        % interest in the Mediator
        %
        % E.g. Example code for subscribing to a particular property:

        % obj.subscribe('PublisherPropertyOfYourChoice',...
        % @(src, event)obj.takeAction(event.AffectedObject.PublisherPropertyOfYourChoice));

        subscribeToMediatorProperties(obj)
    end

    methods (Access = private)
        function unsubscribeMediatorProperties(obj, ~, ~)
            delete(obj.PropEventListenerArray);
        end
    end

    methods
        function obj = Subscriber(mediator)
            obj.Mediator = mediator;
            objWeakRef = matlab.lang.WeakReference(obj);
            obj.SubscribeListener = obj.Mediator.listener(...
                'Subscribe', @(varargin)objWeakRef.Handle.subscribeToMediatorProperties(varargin{:}));
            obj.UnsubscribeListener = obj.Mediator.listener(...
                'Unsubscribe', @(varargin)objWeakRef.Handle.unsubscribeMediatorProperties(varargin{:}));
        end

        % This method can be called from the Subscriber classes in order to
        % subscribe to Mediator properties
        function subscribe(obj, propName, handle)

        % If the requested property does not already exist in the
        % Mediator, then, add the property to the mediator and mark it
        % 'Observable'.
            if ~isprop(obj.Mediator, propName)
                prop = obj.Mediator.addprop(propName);
                prop.SetObservable = true;
            end

            % Add a listener
            obj.PropEventListenerArray(end + 1) = obj.Mediator.listener(propName, 'PostSet', handle);
        end
    end
end
