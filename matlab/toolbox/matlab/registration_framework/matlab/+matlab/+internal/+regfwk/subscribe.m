function subscriptionObject = subscribe(resourceSpecifications, registrationPoint, resourceStateFilter)
    % subscribe Creates a subscription based on the specified parameters and returns a SubscriptionObject.
    % This function uses the 'arguments' block for input validation.
    %
    %   matlab.internal.regfwk.subscribe()

    % Copyright 2024 The MathWorks, Inc.

    arguments
        resourceSpecifications (:,:) matlab.internal.regfwk.ResourceSpecification
        registrationPoint matlab.internal.regfwk.RegistrationPoint
        resourceStateFilter string = "all"
    end

    persistent subscriptionCounter;
    if isempty(subscriptionCounter)
        subscriptionCounter = 1;
    end
    subscriptionObject = matlab.internal.regfwk.SubscriptionObject();

    % Convert resourceSpecifications to an array if it's a single object
    if ~isvector(size(resourceSpecifications))
        resourceSpecifications = [resourceSpecifications];
    end

    resourceSpecificationsJsonStrArray = [];
    for resourceSpecification = resourceSpecifications
        resourceSpecificationJsonStr = string(sprintf('{"resourceName":"%s","resourceType":"%s"}', resourceSpecification.ResourceName, resourceSpecification.ResourceType));
        resourceSpecificationsJsonStrArray = [resourceSpecificationsJsonStrArray, resourceSpecificationJsonStr];
        % replace with mangleEvent when available
        notificationEventTag = strcat('epfwk_events::Notification||', resourceSpecificationJsonStr);

        notificationListener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe( ...
            notificationEventTag, ...
            @registrationPoint.handleNotification);
        subscriptionObject.pushSubscription(notificationListener);
    end

    initialListRequestJsonStr = string(sprintf('{"resourceSpecifications":[%s],"resourceStateFilter":"%s","matlabSubscriptionCounter":"%s"}', strjoin(resourceSpecificationsJsonStrArray, ","), resourceStateFilter, string(subscriptionCounter)));
    initialListEventTag = strcat('epfwk_events::InitialList||', initialListRequestJsonStr);
    initialListListener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe( ...
        initialListEventTag, ...
            @registrationPoint.handleInitialList);
    subscriptionObject.pushSubscription(initialListListener);
    subscriptionCounter = subscriptionCounter + 1;
end