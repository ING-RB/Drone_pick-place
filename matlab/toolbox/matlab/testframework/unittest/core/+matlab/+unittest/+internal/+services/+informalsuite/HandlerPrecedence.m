classdef HandlerPrecedence < uint8
    % HandlerPrecedence - Enumerate precedence of informal suite handlers.
    %
    %   Three main types are defined:
    %       1. Portion - A portion of a test entity
    %       2. Entity - A single test entity
    %       3. Container - A collection of test entities
    %
    %   Within each level, there are 3 sub-levels:
    %       1. Pre - Before core test framework handlers
    %       2. Core - Core test framework handlers
    %       3. Post - After core test framework handlers
    %
    %   Within each of the nine levels, the relative order of located
    %   services is unspecified.

    % Copyright 2022 The MathWorks, Inc.

    enumeration
        PortionPre (0);
        PortionCore (1);
        PortionPost (2);

        EntityPre (3);
        EntityCore (4);
        EntityPost (5);

        ContainerPre (6)
        ContainerCore (7);
        ContainerPost (8);
    end
end
