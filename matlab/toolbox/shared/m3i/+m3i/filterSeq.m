function result = filterSeq(predicate, sequence)
% returns a sequence of all the elements of sequence that satisfy
% predicate. If the input sequence is empty, we return back the input.

%   Copyright 2019 The MathWorks, Inc.

if sequence.isEmpty()
    result = sequence; % can't create new empty sequence without m3iModel
    return;
end

result = M3I.SequenceOfClassObject.make(sequence.at(1).rootModel);

cur = sequence.begin();
last = sequence.end();
while (last ~= cur)
    item = cur.item;
    if (isvalid(item))
        if predicate(item)
            result.append(item);
        end
    end
    cur.getNext;
end
end
