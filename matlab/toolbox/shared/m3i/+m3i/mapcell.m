function ret = mapcell (operation, seq)
    if (iscell(seq))
        ret = cell(1, numel(seq));
        for pos = 1:length(seq)
            ret{pos} = operation(seq{pos});
        end
    else
        ret = cell( 1, prod( double(seq.size()) ) );
        first = seq.begin;
        last = seq.end;
        iter = first;
        pos = 1;
        while iter ~= last
            item = iter.item;
            ret{pos} = operation (item);
            iter.getNext;
            pos = pos + 1;
        end
    end
end