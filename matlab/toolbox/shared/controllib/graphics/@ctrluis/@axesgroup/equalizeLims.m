function limits = equalizeLims(this, ax, LimProp, ~)
% Compute common limits for all axes in handle array AX
% All axes are assumed visible.

% Copyright 2020 The MathWorks, Inc.

Lmin = NaN;
Lmax = NaN;
for ct=1:prod(size(ax))
    Lims = get(ax(ct),LimProp);
    if strcmpi(LimProp,'YLim') && isequal(Lims,[0 1]) && ...
            this.CheckForBlankAxes && isAxesBlank(ax(ct))
        Lims = [NaN, NaN];
    end
    Lmin = min(Lmin,Lims(1));
    Lmax = max(Lmax,Lims(2));
end
limits = [Lmin Lmax];
if any(isnan(limits))
    limits = [0 1];
end

end

function flag = isAxesBlank(ax)
h = findall(ax,'Type','line');
flag = ~any(strcmp({h.Visible},'on'));
end


