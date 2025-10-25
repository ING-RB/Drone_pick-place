function renameMaterial(root, actualMaterialName, newMaterialName)
    % Recursive helper function
    function updateNodes(node)
        if ~isempty(node.Mesh)
            materials = node.Mesh.Materials;
            for i = 1:length(materials)
                if strcmp(materials(i).Name, actualMaterialName)
                    materials(i).Name = newMaterialName; % Update the material name
                end
            end
            node.Mesh.Materials = materials; % Update the node's materials
        end
        for i = 1:length(node.Children)
            updateNodes(node.Children(i)); % Recursively update the children
        end
    end

    % Start the recursive update from the root node
    updateNodes(root);
end