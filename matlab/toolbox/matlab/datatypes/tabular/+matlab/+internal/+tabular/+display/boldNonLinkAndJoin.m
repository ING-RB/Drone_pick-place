function str = boldNonLinkAndJoin(nonLink,Link,strongBegin,strongEnd)
    needsTags = (strlength(strtrim(nonLink)) > 0);
    nonLink(needsTags) = strongBegin + nonLink(needsTags) + strongEnd;
    if ~isempty(Link)
        str = join(nonLink,Link);
    else
        str = nonLink;
    end
end
