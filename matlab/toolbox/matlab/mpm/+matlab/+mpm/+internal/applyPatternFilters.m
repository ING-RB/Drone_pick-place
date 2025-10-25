function [mask] = applyPatternFilters(pkg, patternOpts)
% Apply pattern filters for mpmsearch and mpmlist

%   Copyright 2024 The MathWorks, Inc.

    mask = true(1, length(pkg));

    if ~isempty(pkg)
        if ismember("Name",fieldnames(patternOpts))
            name_mask = matches([pkg.Name], patternOpts.Name);

            for i = 1:numel(pkg)
                p = pkg(i);
                name_mask(i) = name_mask(i) | any(matches([p.FormerNames], patternOpts.Name));
            end

            mask = mask & name_mask;
        end

        if ismember("DisplayName",fieldnames(patternOpts))
            mask = mask & matches([pkg.DisplayName], patternOpts.DisplayName);
        end
    end
end
