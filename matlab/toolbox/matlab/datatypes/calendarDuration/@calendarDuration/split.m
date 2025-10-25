function [varargout] = split(this,units)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[~,units] = matlab.internal.datetime.checkCalendarComponents(units,true);

nargoutchk(0,length(units));
varargout = cell(1,min(length(units),max(nargout,1)));

% Expand scalar zero placeholders out to the full size. May also have to put
% appropriate nonfinites into elements of fields that were expanded.
components = calendarDuration.expandScalarZeroPlaceholders(this.components);
[components,nonfiniteElems,nonfiniteVals] = calendarDuration.reconcileNonfinites(components);
mo = components.months; d = components.days; ms = components.millis;

for i = 1:length(varargout)
    switch units{i}
    case 'years'
        y = fix(mo / 12);
        mo = rem(mo,12);
        if ~isempty(nonfiniteVals), mo(nonfiniteElems) = nonfiniteVals; end
        varargout{i} = y;
    case 'quarters'
        q = fix(mo / 3);
        mo = rem(mo,3);
        if ~isempty(nonfiniteVals), mo(nonfiniteElems) = nonfiniteVals; end
        varargout{i} = q;
    case 'months'
        varargout{i} = mo;
    case 'weeks'
        w = fix(d / 7);
        d = rem(d,7);
        if ~isempty(nonfiniteVals), d(nonfiniteElems) = nonfiniteVals; end
        varargout{i} = w;
    case 'days'
        varargout{i} = d;
    case 'time'
        varargout{i} = duration.fromMillis(ms);
    end
end
