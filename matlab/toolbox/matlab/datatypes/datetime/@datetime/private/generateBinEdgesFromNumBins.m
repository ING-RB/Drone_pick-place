function edges = generateBinEdgesFromNumBins(numbins,xmin,xmax,hardlimits)
%GENERATEBINEDGESFROMNUMBINS Generate bin edges from number of bins.
%   EDGES = GENERATEBINEDGESFROMNUMBINS(NUMBINS,XMIN,XMAX,HARDLIMITS)
%   returns a vector of datetime edges of uniform width separating NUMBINS
%   bins and generated using the datetime limits XMIN and XMAX. If
%   HARDLIMITS is true, then XMIN and XMAX are forced to be the first and
%   last edges. Otherwise, the first and last edges are calculated and may
%   be different than XMIN and XMAX.

%   Copyright 2016-2020 The MathWorks, Inc.

numbins = double(numbins);

if hardlimits
    edges = linspace(xmin,xmax,numbins+1);
else
    % try from coarsest to finest levels
    levels = {'year', 'month', 'day', 'hour', 'minute', 'second'};
    funcs = {@calyears, @calmonths, @caldays, @hours, @minutes, @seconds};
    edges = [];
    for ind = 1:length(levels)
        unit = levels{ind};
        func = funcs{ind};
        xminstart = dateshift(xmin,'start',unit);
        xmaxnext = dateshift(xmax,'start',unit,'next');
        if matches(unit, ["year", "month", "day"])
            span = func(between(xminstart,xmaxnext,unit));
        else
            span = func(xmaxnext - xminstart);
        end
        if span > numbins
            if numbins == 1
                edges = [xminstart xmaxnext];
            elseif numbins == 2
                bw = ceil(span / 2);
                midpoint = xminstart + func(floor(span/2));
                edges = midpoint + func((-1:1)*bw);
            else % numbins >= 3
                % determine shortest and longest binwidth possible, and determine if
                % there is an integer between them
                bwshortest = span / numbins;
                bwlongest = (span-2)/(numbins-2);
                bw = ceil(bwshortest); % integer
                if bw < bwlongest
                    midpoint = xminstart + func(floor(span/2));
                    if rem(numbins,2) == 1 % odd number of bins
                        if rem(span,2) == 1  % odd span
                            if rem(bw,2) == 1 % odd bin width
                                rawhalflength = bw*(ceil(...
                                    span/2/bw-0.5)+0.5);
                                lefthalflength = func(floor(rawhalflength));
                                righthalflength = func(ceil(rawhalflength));
                            else   % even bin width
                                lefthalflength = func(bw*(ceil(...
                                    span/2/bw-0.5)+0.5));
                                righthalflength = lefthalflength;
                            end
                        else  % even span
                            if rem(bw,2) == 1 % odd bin width
                                rawhalflength = bw*(...
                                    ceil(span/2/bw-0.5)+0.5);
                                lefthalflength = func(ceil(rawhalflength));
                                righthalflength = func(floor(rawhalflength));
                            else  % even bin width
                                lefthalflength = func(bw*(ceil(span/2/bw-0.5)+0.5));
                                righthalflength = lefthalflength;
                            end
                        end
                    else  % even number of bins
                        lefthalflength = func(bw*ceil(ceil(span/2)/bw));
                        righthalflength = lefthalflength;
                    end
                    leftedge = midpoint - lefthalflength;
                    rightedge = midpoint + righthalflength;
                    bw = func(bw);
                    edges = leftedge:bw:rightedge;
                end
            end
            if ~isempty(edges)
                break; %break out of the loop
            end
        end
    end
    if isempty(edges)
        % if still empty, simply use binpicker on numeric time. datetime has no origin, so
        % center them so binPicker (almost) won't ever treat them as "constant with
        % respect to scale".
        pxmin = posixtime(xmin);
        pxmax = posixtime(xmax);
        edges = matlab.internal.math.binpicker(0,pxmax-pxmin,numbins,(pxmax-pxmin)/numbins);
        edges = datetime(edges+pxmin,'convertFrom', 'posixtime', 'TimeZone', xmin.tz);
    end
end
end
