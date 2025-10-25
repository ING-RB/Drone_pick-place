function result = fold(functionHandle, sequence, intialValue)
    result = intialValue; 
    iter = sequence.begin;
    last = sequence.end;
    while iter ~= last
        item = iter.item;
        result = functionHandle(item, result);
        iter.getNext;
    end
end