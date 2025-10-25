function result = commaList(setOfStrings, prefix)
    if (nargin == 1)
        prefix = '';
    end
    stream = m3i.ostringstream;
    first = true;
    for i = 1:numel(setOfStrings)
        if ~isempty(setOfStrings{i})
            if (first)
                first = false;
                comma = '';
            else
                comma = ', ';
            end
            stream.sprintf('%s%s%s', comma, prefix, setOfStrings{i});
        end
    end
    result = stream.string;
end