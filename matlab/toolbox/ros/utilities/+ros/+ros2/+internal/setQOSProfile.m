function qosProfile = setQOSProfile(rmwProfile, qosHist, qosDepth, qosReliability, qosDurability, ...
    qosDeadline, qosLifespan, qosLiveliness, qosLeaseDuration, qosAvoidROSNamespaceConventions)
% SETQOSPROFILE Set the QoS profile values as specified
% This method uses the enumerations for history, durability, reliability 
% and liveliness values as specified in 'rmw/types.h' header.

%   Copyright 2021-2023 The MathWorks, Inc.
%#codegen
coder.cinclude('mlros2_qos.h');
opaqueHeader = {'HeaderFile', 'rmw/types.h'};
if isequal(coder.internal.toLower(qosHist), 'keepall')
    history = coder.opaque('rmw_qos_history_policy_t', ...
        'RMW_QOS_POLICY_HISTORY_KEEP_ALL', opaqueHeader{:});
    qosDepth = double(intmax('int32'));
else
    history = coder.opaque('rmw_qos_history_policy_t', ...
        'RMW_QOS_POLICY_HISTORY_KEEP_LAST', opaqueHeader{:});
end
if isequal(coder.internal.toLower(qosReliability), 'reliable')
    reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
        'RMW_QOS_POLICY_RELIABILITY_RELIABLE', opaqueHeader{:});
else
    reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
        'RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT', opaqueHeader{:});
end
if isequal(coder.internal.toLower(qosDurability), 'transientlocal')
    durability = coder.opaque('rmw_qos_durability_policy_t', ...
        'RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL', opaqueHeader{:});
else
    durability = coder.opaque('rmw_qos_durability_policy_t', ...
        'RMW_QOS_POLICY_DURABILITY_VOLATILE', opaqueHeader{:});
end
if isequal(coder.internal.toLower(qosLiveliness), 'automatic')
    liveliness = coder.opaque('rmw_qos_liveliness_policy_t', ...
        'RMW_QOS_POLICY_LIVELINESS_AUTOMATIC', opaqueHeader{:});
else
    liveliness = coder.opaque('rmw_qos_liveliness_policy_t', ...
        'RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC', opaqueHeader{:});
end

depth = cast(qosDepth,'like',coder.opaque('size_t','0'));

% Convert duration-based QOS settings from double to struct format to
% assign values to the rmw_time_t structure
sec = floor(qosDeadline);
nsec = (qosDeadline - sec) * 1e9;
deadline = struct('sec', sec, 'nsec', nsec);

sec = floor(qosLifespan);
nsec = (qosLifespan - sec) * 1e9;
lifespan = struct('sec', sec, 'nsec', nsec);

sec = floor(qosLeaseDuration);
nsec = (qosLeaseDuration - sec) * 1e9;
liveliness_lease_duration = struct('sec', sec, 'nsec', nsec);

avoid_ros_namespace_conventions = cast(qosAvoidROSNamespaceConventions,'like',coder.opaque('bool','false'));

% Use SET_QOS_VALUES macro to set the
% structure members of rmw_qos_profile_t structure, The macro takes in
% the rmw_qos_profile_t structure and assigns the history, depth,
% durability, reliability, deadline, lifespan, liveliness, 
% liveliness_lease_duration and avoid_ros_namespace_conventions values 
% specified on system block to the qos_profile variable in generated 
% C++ code.
if coder.target('Rtw')
    coder.ceval('SET_QOS_VALUES', rmwProfile, history, depth, ...
        durability, reliability, deadline, lifespan, liveliness, ...
        liveliness_lease_duration, avoid_ros_namespace_conventions);
end
qosProfile = rmwProfile;
end

% LocalWords:  rmw qos keepall
