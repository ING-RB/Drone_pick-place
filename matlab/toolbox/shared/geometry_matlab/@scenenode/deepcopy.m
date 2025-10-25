% Method to create a deep copy of the node
function newObj = deepcopy(obj)
    % Create a copy of the current node
    newObj = obj.copy();
    newObj.Mesh = copy(obj.Mesh);
    
    % Recursively copy each child and add to the new node
    newObj.Children = scenenode.empty; % Clear children of the new node
    for i = 1:length(obj.Children)
        newObj.Children(i) = deepcopy(obj.Children(i));
    end
end