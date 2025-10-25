% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.ConfigElement.serializeInternal
% THIS FILE WILL NOTE BE REGENERATED
function result = serializeInternal(obj)
    arguments(Output)
        result string
    end
    s = mf.zero.io.HumaneJSONSerializer();
    result = s.serializeToString(obj.Internal);
end
