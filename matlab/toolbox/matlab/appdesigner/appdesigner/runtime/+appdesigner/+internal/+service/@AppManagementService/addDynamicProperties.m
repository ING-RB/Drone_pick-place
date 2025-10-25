function addDynamicProperties(model, propName, propValue, hidden, transient)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        model 
        propName 
        propValue 
        hidden = false;
        transient = true;
    end

    if ~isprop(model, propName)
        propIns = addprop(model, propName);
        propIns.Transient = transient;
        propIns.Hidden = hidden;

        model.(propName) = propValue;
    end
end
