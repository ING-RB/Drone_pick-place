function rep = compactRepresentationForSingleLine(obj,displayConfiguration,~)
%% Custom display ArgumentIdentifer.
    
% Copyright 2023 The MathWorks, Inc.

    strVec = strings(1,numel(obj));
    for i=1:numel(obj)
        groupName = obj(i).NameGroup;
        if isempty(groupName) || groupName == ""
            strVec(i) = obj(i).Name;
        else
            strVec(i) = obj(i).NameGroup + "." + obj(i).Name;
        end
    end
    rep = fullDataRepresentation(obj,displayConfiguration, "StringArray", strVec);
end
