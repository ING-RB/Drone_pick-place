classdef SubscriptionObject < handle
    % SubscriptionObject Class to manage subscription listeners.

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = private)
        Listeners = {} % Initialize an empty cell array to hold listeners
    end

    methods
        function pushSubscription(obj, listener)
            % Adds a listener handle to the subscription list.
            obj.Listeners{end+1} = listener;
        end

        function unsubscribe(obj)
            % Clears all listeners from the subscription.
            % Iterate through the Listeners array and delete connections
            for i = 1:length(obj.Listeners)
                delete(obj.Listeners{i});
                obj.Listeners{i} = [];
            end
            % Then clear the Listeners array
            obj.Listeners = {};
        end

        function delete(obj)
            % unsubscribe all listeners in the destructor as well
            unsubscribe(obj);
        end
    end
end
