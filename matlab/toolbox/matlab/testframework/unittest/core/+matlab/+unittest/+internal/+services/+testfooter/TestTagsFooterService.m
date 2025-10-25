classdef TestTagsFooterService < matlab.unittest.internal.services.testfooter.TestFooterService
    %

    % Copyright 2022 The MathWorks, Inc.

    methods (Access=protected)
        function footer = getFooter(~, suite, ~)
            import matlab.unittest.internal.diagnostics.PlainString;
            import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;

            tags = unique([suite.Tags]);
            numTags = numel(tags);
            if numTags == 0
                label = getString(message("MATLAB:unittest:TestSuite:ZeroTagsFooter"));
            elseif numTags == 1
                label = getString(message("MATLAB:unittest:TestSuite:SingleTagFooter"));
            else
                label = getString(message("MATLAB:unittest:TestSuite:MultipleTagsFooter", numTags));
            end

            % Early return if hyperlinking is not necessary
            if isempty(tags)
                footer = PlainString(label);
                return;
            end

            encodedTags = cellfun(@mat2str, cellfun(@double, tags, UniformOutput=false), UniformOutput=false);
            commandToDisplayTags = sprintf("matlab.unittest.internal.diagnostics.displayCellArrayAsTable({%s}, {'%s'})", ...
                sprintf("%s;", encodedTags{:}), "Tag");
            footer = CommandHyperlinkableString(label, commandToDisplayTags);
        end
    end
end

% LocalWords:  Hyperlinkable
