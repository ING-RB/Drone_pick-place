function result = filter(predicate, sequence)
% returns a cellarray of all the elements of sequence that satifsy
% predicate
result = {};
if (iscell(sequence))
    for i = 1:length(sequence)
        if predicate(sequence{i})
            result{end+1} = sequence{i};
        end
    end
else
    cur = sequence.begin();
    last = sequence.end();
    while (last ~= cur)
        item = cur.item;
        if (isvalid(item))
            if predicate(item)
                result{end+1} = item;
            end
        else
            disp('invalid item');
        end
        cur.getNext;
    end
end
end