% This function mirrors the client-side PortPlacementPolicy, which
% applies a minimum size to elements based on port location. In client-server
% topology, it is necessary to reflect the resize in the server where undo/redo
% is expected to revert the resize.
function resizeEntityForPorts(operations, entity)
    portsArray = entity.ports;
    spacing = 30;
    enumValues = enumeration('diagram.interface.Location');
    literals = arrayfun(@char, enumValues, 'UniformOutput', false);
    locations = containers.Map(literals, repmat({{}}, size(literals)));
    ports = containers.Map();

    for i = 1:length(portsArray)
        port = portsArray(i);
        location = port.location;
        id = port.uuid;
        
        if isKey(locations, char(location))
            locations(char(location)) = [locations(char(location)), {id}];
        end
        
        ports(id) = port;
    end
    height = max(length(locations('Left')) * spacing + spacing, ...
                length(locations('Right')) * spacing + spacing);
    width = max(length(locations('Top')) * spacing + spacing, ...
                length(locations('Bottom')) * spacing + spacing);
    dimensions.width = max(width, entity.getSize.width);
    dimensions.height = max(height, entity.getSize.height);
    operations.setSize(entity, dimensions.width, dimensions.height);
end
