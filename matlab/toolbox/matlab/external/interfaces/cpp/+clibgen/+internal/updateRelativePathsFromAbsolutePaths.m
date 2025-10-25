function parsedResults = updateRelativePathsFromAbsolutePaths(parsedResults)
% Update relative paths from absolute paths

%   Copyright 2024 The MathWorks, Inc.

    parsedResults.HeaderFilesRelative = updateRelativePaths(parsedResults.HeaderFilesRelative, string(parsedResults.HeaderFiles));
    parsedResults.LibrariesRelative = updateRelativePaths(parsedResults.LibrariesRelative, string(parsedResults.Libraries));
    % Libraries count may increase, add them to LibrariesRelative
    libs = string(parsedResults.Libraries);
    while length(libs) > length(parsedResults.LibrariesRelative)
        endidx = length(parsedResults.LibrariesRelative);
        parsedResults.LibrariesRelative(end+1) = libs(endidx+1);
    end
    parsedResults.IncludePathRelative = updateRelativePaths(parsedResults.IncludePathRelative, string(parsedResults.IncludePath));
    parsedResults.OutputFolderRelative = updateRelativePaths(parsedResults.OutputFolderRelative, string(parsedResults.OutputFolder));
    parsedResults.SupportingSourceFilesRelative = updateRelativePaths(parsedResults.SupportingSourceFilesRelative, string(parsedResults.SupportingSourceFiles));

        function relativePaths = updateRelativePaths(relativePaths, absolutePaths)
            for idx = 1:length(relativePaths)
                if ~startsWith(relativePaths(idx), "<")
                    relativePaths(idx) = absolutePaths(idx);
                end
            end
        end

end
