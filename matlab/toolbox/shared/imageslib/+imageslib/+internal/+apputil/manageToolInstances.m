function manageToolInstances(action, handleName, handleInstance)
% MANAGETOOLINSTANCES Tracks multiple instances of an App
%
% API:
%  manageToolInstances('add','images.internal.someTool', h)
%   Add a handle of a created App to the tracked list.
%  manageToolInstances('remove','images.internal.someTool', h)
%   Remove handle from tracked list.
%  manageToolInstances('deleteAll','images.internal.someTool')
%   Call the destructor on all tracked App instances.
%

%     Copyright 2014 The MathWorks, Inc.

mlock();
% munlock('iptui.internal.manageToolInstances')

validateattributes(action,...
    {'char'}, {'nonempty', 'vector'});
validateattributes(handleName,...
    {'char'}, {'nonempty', 'vector'});
if(nargin==3)
    assert(isa(handleInstance,'handle'));
end

persistent toolArrayMap
if(isempty(toolArrayMap))
    toolArrayMap = containers.Map();
end

switch action
    case 'add'
        if(isKey(toolArrayMap, handleName))
            toolArray = toolArrayMap(handleName);
            if(isempty(toolArray))
                toolArray = handleInstance;
            else
                toolArray(end+1) = handleInstance;
            end
            toolArrayMap(handleName) = toolArray;
        else
            toolArrayMap(handleName) = handleInstance;
        end
        
    case 'remove'
        if(isKey(toolArrayMap, handleName))
            toolArray = toolArrayMap(handleName);
            for hInd = 1:length(toolArray)
                if isequal(handleInstance, toolArray(hInd))
                    toolArray(hInd) = [];
                    break;
                end
            end
            toolArrayMap(handleName) = toolArray;
        end
        
    case 'deleteAll'
        if(isKey(toolArrayMap, handleName))
            toolArray = toolArrayMap(handleName);
            for hInd = length(toolArray):-1:1
                delete(toolArray(hInd));
            end
            remove(toolArrayMap,handleName);
        end
        
    otherwise
        assert(false, 'Unknown action requested');
end

end
