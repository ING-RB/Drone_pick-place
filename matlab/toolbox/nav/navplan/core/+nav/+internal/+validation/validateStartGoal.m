function [isValid] = validateStartGoal(validator,state,statevarname,funcname)
% This function is for internal use only. It may be removed in the future.

%   Copyright 2022-2024 The MathWorks, Inc.
%#codegen

% Validate for supported state validators.
    validateattributes(validator, {'validatorOccupancyMap', 'validatorVehicleCostmap'}, {}, funcname, 'StateValidator');

    isValid = validator.isStateValid(state);

    if(~isValid)
        % Proceeding only if state is given invalid by validator.

        % Extracting map from validator
        map = validator.Map;

        % Variables used to print messages.
        strX = 'X direction';
        strY = 'Y direction';

        % Extracting map limits in each direction.
        if(isa(map,'binaryOccupancyMap')||isa(map,'occupancyMap'))

            [isOccupied, idxInBounds] = map.checkOccupancy(state(1:2));
            % binaryOccupancyMap or occupancyMap
            mapSizeX = map.XWorldLimits;
            mapSizeY = map.YWorldLimits;

        elseif(isa(map,'vehicleCostmap'))

            % Verifying if state is occupied or not.
            isOccupied = map.checkOccupied(state(1:2));

            % Extracting map from vehicleCostMap
            mapSizeX = map.MapExtent(1:2);
            mapSizeY = map.MapExtent(3:4);

            % Verifying if state is within limits.
            idxInBounds = ~(any([state(1) state(2)]>[mapSizeX(2) mapSizeY(2)])||...
                            any([state(1) state(2)]<[mapSizeX(1) mapSizeY(1)]));
        end

        if(~idxInBounds)
            % Out of bounds
            if coder.target('MATLAB')
                error(message('nav:navalgs:validatestartgoal:CoordinateOutside', statevarname,...
                              sprintf('%0.1f',mapSizeX(1)), sprintf('%0.1f',mapSizeX(2)),strX, ...
                              sprintf('%0.1f',mapSizeY(1)), sprintf('%0.1f',mapSizeY(2)),strY));
            else
                coder.internal.error('nav:navalgs:validatestartgoal:CoordinateOutside', statevarname,...
                                     coder.internal.num2str(mapSizeX(1)), coder.internal.num2str(mapSizeX(2)),strX, ...
                                     coder.internal.num2str(mapSizeY(1)), coder.internal.num2str(mapSizeY(2)),strY);
            end
        elseif(isOccupied)
            % Pose Occupied
            coder.internal.errorIf(any(logical(isOccupied)),'nav:navalgs:validatestartgoal:OccupiedLocation', statevarname);
        else
            coder.internal.error('nav:navalgs:validatestartgoal:InvalidPose',statevarname);
        end
    end
end