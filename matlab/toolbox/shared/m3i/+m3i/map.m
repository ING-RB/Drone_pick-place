function ret = map (fh, seq)
    ret = zeros( 1, prod( double(seq.size()) ) ); 
    first = seq.begin;
    last = seq.end;
    iter = first;
    pos = 1;
    while iter ~= last
        item = iter.item;
        ret(pos) = fh (item);
        iter.getNext;
        pos = pos + 1;
    end
end