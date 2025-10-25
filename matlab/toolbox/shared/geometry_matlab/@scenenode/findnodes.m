function matchingNodes = findnodes(root, name)
    % Initialize an empty cell array to hold the matching nodes
    matchingNodes = scenenode.empty;

    % Recursive helper function
    function searchNodes(node)
        if strcmp(node.Name, name)
            matchingNodes(end + 1) = node; % Add the matching node to the list
        end
        for i = 1:length(node.Children)
            searchNodes(node.Children(i)); % Recursively search the children
        end
    end

    % Start the recursive search from the root node
    searchNodes(root);
end
