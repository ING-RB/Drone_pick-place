function steerAngle = headingRateToSteeringAngle(vehicleInputs, bicycleKinematicsObj)
%

%   Copyright 2023 The MathWorks, Inc.

    arguments
        vehicleInputs (:,2) {mustBeNumeric, mustBeNonNan, mustBeFinite, mustBeReal}
        bicycleKinematicsObj  (1,1) {mustBeA(bicycleKinematicsObj, "bicycleKinematics")}
    end

    velocityOOB = any(vehicleInputs(:,1)<bicycleKinematicsObj.VehicleSpeedRange(1)) ...
        || any(vehicleInputs(:,1)>bicycleKinematicsObj.VehicleSpeedRange(2));
    if velocityOOB
        coder.internal.error("nav:navalgs:headingratetosteeringangle:VelocityViolation",...
                             bicycleKinematicsObj.VehicleSpeedRange(1), ...
                             bicycleKinematicsObj.VehicleSpeedRange(2));
    end

    steerAngle = atan2(bicycleKinematicsObj.WheelBase.*vehicleInputs(:,2),vehicleInputs(:,1));
    steerAngle = min(steerAngle, bicycleKinematicsObj.MaxSteeringAngle);
    steerAngle = max(steerAngle, -bicycleKinematicsObj.MaxSteeringAngle);

end
