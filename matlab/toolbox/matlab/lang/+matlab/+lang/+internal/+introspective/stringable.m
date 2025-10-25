classdef (HandleCompatible) stringable
    methods
        function s = string(obj)
            props = fieldnames(obj);
            vals = cellfun(@(f)string(obj.(f)), props, "UniformOutput", false);
            props = append(props, ':');
            props(2:end) = append(newline, props(2:end));
            pv = [props, vals]';
            s = join([pv{:}],'');
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.
