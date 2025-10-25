% Converts a dataset to a table

% Copyright 2020-2022 The MathWorks, Inc.

function tb = convertDatasetToTable(ds)
    arguments
        ds dataset %#ok<DTSET>
    end

    % Disable warnings that dataset2table may throw so they don't appear at the
    % command line
    w = warning("off", "all");
    c = onCleanup(@() warning(w));
    tb = dataset2table(ds);
end