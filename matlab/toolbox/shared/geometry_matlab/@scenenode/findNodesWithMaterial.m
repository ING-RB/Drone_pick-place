function matchingNodes = findNodesWithMaterial(root, materialName)
    % Initialize an empty cell array to hold the matching nodes
    matchingNodes = {};

    % Recursive helper function
    function searchNodes(node)
        if ~isempty(node.Mesh)
            materials = node.Mesh.Materials;
            for i = 1:length(materials)
                if strcmp(materials(i).Name, materialName)
                    matchingNodes{end + 1} = node; % Add the matching node to the list
                    break;
                end
            end
        end
        for i = 1:length(node.Children)
            searchNodes(node.Children(i)); % Recursively search the children
        end
    end

    % Start the recursive search from the root node
    searchNodes(root);
end
