function tf = containsRegexp(text,pat)
starts = regexp(text,pat,'once');
if iscell(starts)
    tf = ~cellfun('isempty',starts);
else
    tf = ~isempty(starts);
end
end