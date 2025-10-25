classdef Publisher < handle
%PUBLISHER - Superclass for Publisher Classes.

% Publisher classes are the ones that are interested in publishing one
% or more properties. Any class that wishes to be a publisher should
% inherit from the 'Publisher' class. If a property is to be published,
% then 'SetObservable' should be set to true. 'AbortSet' is optional.
% If 'AbortSet' is set as true, then the subscriber handlers won't be
% triggered if the publisher property is set with the same value.
%
% Note:
% 1. Multiple publisher classes can have the same property name.
% Subscribers will only know about the property name and will not
% differentiate between publishers who are publishing them. If your
% design calls for the subscribers to be able to differentiate among
% publishers, then please consider having specific property names.

% Copyright 2016-2024 The MathWorks, Inc.

    properties (Access = private)
        Mediator (1,1) matlabshared.mediator.internal.Mediator
        PropEventListenerArray = event.proplistener.empty
    end

    methods
        function obj = Publisher(mediator)
            obj.Mediator = mediator;
            obj.addObservablePropertiesToMediator();
        end
    end

    methods (Access = private)
        function addObservablePropertiesToMediator(obj)
        % Finds all properties with SetObservable 'true' and adds them
        % to the Mediator
            propList = meta.class.fromName(class(obj)).PropertyList;

            for i = 1:length(propList)
                % If the property has setObservable 'true' and if the
                % same property is already not present in the mediator obj,
                % then add it to the mediator or else get the property
                % object from the mediator.
                if propList(i).SetObservable
                    if ~isprop(obj.Mediator, propList(i).Name)
                        % Add the property to the Mediator
                        prop = obj.Mediator.addprop(propList(i).Name);
                        prop.SetObservable = true;
                    else
                        % Get the property from mediator
                        prop = obj.Mediator.findprop(propList(i).Name);
                    end

                    % Reflect the status of 'AbortSet' accurately on the
                    % mediator object's property too
                    prop.AbortSet = propList(i).AbortSet;

                    % Add listener to each observable property in the
                    % publisher class, that would listen to any change and
                    % propagate that change to the corresponding copy or
                    % the property in the Mediator
                    objWeakRef = matlab.lang.WeakReference(obj);
                    obj.PropEventListenerArray(end + 1) = obj.listener(propList(i).Name, 'PostSet', @(varargin)objWeakRef.Handle.setMediatorProp(varargin{:}));
                end
            end
        end

        function setMediatorProp(obj, src, evt)
            obj.Mediator.(src.Name) = evt.AffectedObject.(src.Name);
        end
    end
end
