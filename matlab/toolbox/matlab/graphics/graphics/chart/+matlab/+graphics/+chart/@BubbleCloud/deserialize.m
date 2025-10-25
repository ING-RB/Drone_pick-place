function deserialize(obj,data)
%

%   Copyright 2020 The MathWorks, Inc.

% This method is called during deserialization. It takes all serialized
% fields (in the DataStorage struct) and puts them back into properties (of 
% the object).
%
% Serialization and deserialization both use the public interface (i.e. no 
% _I properties). This ensures that any code in the setter runs (including 
% triggering modes).

% Peel off properties that shouldn't be directly deserialized
data=rmfield(data,{'Version' 'Date'}); % Reserved for future use

f=fieldnames(data);
for i = 1:numel(f)
    if isprop(obj,f{i})
        obj.(f{i})=data.(f{i});
    end
end

end
