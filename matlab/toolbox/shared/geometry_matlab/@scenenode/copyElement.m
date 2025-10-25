function cpObj = copyElement(obj)
    % Call the copyElement method of the superclass
    cpObj = copyElement@matlab.mixin.Copyable(obj);
    
    % Perform a deep copy of the Mesh property
    if ~isempty(obj.Mesh)
        cpObj.Mesh = copy(obj.Mesh);
    end
    
    % Recursively copy each child and add to the new node
    cpObj.Children = scenenode.empty; % Clear children of the new node
    for i = 1:length(obj.Children)
        cpObj.Children(i) = copy(obj.Children(i));
    end
end