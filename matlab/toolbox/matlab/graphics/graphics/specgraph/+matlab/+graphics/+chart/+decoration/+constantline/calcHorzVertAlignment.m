function [horzA, vertA] = calcHorzVertAlignment(ax, ha, va, lo)
%Determines text primitive alignments based on ConstantLine's alignments

%   Copyright 2018 The MathWorks, Inc.

    x = 'x'; y = 'y'; l = 'left'; c = 'center'; r = 'right'; 
    b = 'bottom'; m = 'middle'; t = 'top'; h = 'horizontal'; a = 'aligned';

    ykeys = {t, m, b};
    yvalues = {{ha, b}, {ha, m}, {ha, t}};

    xkeys = {[x l t a], [x l m a], [x l b a], [x l t h], [x l m h], [x l b h],... 
             [x c t a], [x c m a], [x c b a], [x c t h], [x c m h], [x c b h],...
             [x r t a], [x r m a], [x r b a], [x r t h], [x r m h], [x r b h]};
    xvalues = {{r b}, {c b}, {l b}, {r va}, {r va}, {r va},...
               {r m}, {c m}, {l m}, {c va}, {c va}, {c va},...
               {r t}, {c t}, {l t}, {l va}, {l va}, {l va}};
    map = containers.Map([xkeys ykeys], [xvalues yvalues]);
    switch ax
        case y
            outputs = map(va);
        case x
            outputs = map([x ha va lo]);
    end
    
    [horzA, vertA] = outputs{:};

end
