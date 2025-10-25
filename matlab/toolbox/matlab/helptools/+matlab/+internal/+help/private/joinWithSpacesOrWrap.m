function joinedList = joinWithSpacesOrWrap(list, preSeparator, args)
    arguments
        list                (1,:) string;
        preSeparator        (1,1) string;
        args.prefix         (1,1) string = "";
        args.wantHyperlinks (1,1) logical = false;
        args.indentWrapped  (1,1) logical = false;
    end
    list(1:end-1) = list(1:end-1) + preSeparator;
    prefix = indent(0.5) + args.prefix;
    prefixLength = matlab.internal.display.wrappedLength(prefix, args.wantHyperlinks);
    joinedList = prefix + list(1);
    currentLength = prefixLength + matlab.internal.display.wrappedLength(list(1), args.wantHyperlinks);
    if args.indentWrapped
        prefix = indent + prefix;
        prefixLength = strlength(indent) + prefixLength;
    end
    for listItem = list(2:end)
        itemLength = matlab.internal.display.wrappedLength(listItem, args.wantHyperlinks);
        currentLength = currentLength + 1 + itemLength;
        if currentLength > lineLength
            joinedList = joinedList + newline + prefix;
            currentLength = prefixLength + itemLength;
        else
            joinedList = joinedList + " ";
        end
        joinedList = joinedList + listItem;
    end
end

%   Copyright 2022 The MathWorks, Inc.
