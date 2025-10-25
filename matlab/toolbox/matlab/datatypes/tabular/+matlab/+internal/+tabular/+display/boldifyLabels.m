function [names, hasLinks] = boldifyLabels(names,bold,strongBegin,strongEnd)
% Make varnames/rownames bold. If the name contains a hyperlink, they need
% to be handled differently because the Command Window will end up
% displaying the literal <strong> tags.
hasLinks = matlab.internal.tabular.display.containsRegexp(names,'a\s+href\s*=');
if bold && strlength(strongBegin) > 0
    if any(hasLinks)
        names(hasLinks) = matlab.internal.tabular.display.boldifyLinks(names(hasLinks),strongBegin,strongEnd);
    end
    names(~hasLinks) = strongBegin + names(~hasLinks) + strongEnd;
end
end

