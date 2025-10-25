function foreach(operation, sequence)
if (iscell(sequence))
    for i = 1:length(sequence)
        operation(sequence{i});
    end
else
    cur = sequence.begin();
    last = sequence.end();
    while (last ~= cur)
        item = cur.item;
        if (isvalid(item))
            operation(item);
        else
            disp('invalid item');
        end
        cur.getNext;
    end
end
end