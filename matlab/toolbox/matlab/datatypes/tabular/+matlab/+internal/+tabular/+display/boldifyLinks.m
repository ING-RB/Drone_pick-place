function strs = boldifyLinks(strs,strongBegin,strongEnd)
    % adds the bold to hyperlinks
    import matlab.internal.tabular.display.boldNonLinkAndJoin;
    hotlinkPattern = "(<a\s+href\s*=\s*""[^""]*""[^>]*)(>.*?</a>)";
    strs = regexprep(strs, hotlinkPattern, "$1 style=""font-weight:bold""$2");
    % break each string into non-anchor, and anchor parts, then bold the
    % non-anchor parts
    [nonLinkText,links] = regexp(strs, hotlinkPattern, 'split', 'match');
    if iscell(nonLinkText)
        for i = 1:numel(strs)
            strs(i) = boldNonLinkAndJoin(nonLinkText{i},links{i},strongBegin,strongEnd);
        end
    else
        strs = boldNonLinkAndJoin(nonLinkText,links,strongBegin,strongEnd);
    end
end
