% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.Config.getElement
% THIS FILE WILL NOTE BE REGENERATED
function result = getElement(obj, id)
    arguments(Input)
        obj studio.config.api.Config
        id string
    end
    arguments(Output)
        result studio.config.api.ConfigElement
    end
    result = [];
    for ii = 1:length(obj.Elements)
        element = obj.Elements(ii);
        if strcmp(element.Name, id)
            result = element;
        end
    end
    if isempty(result)
        % todo: i18n
        error(strcat("Element with Name ", strcat( id, " does not exist in Config")));
    end
end
