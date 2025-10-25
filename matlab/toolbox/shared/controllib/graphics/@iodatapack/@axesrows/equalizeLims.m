function limits = equalizeLims(this, ax,LimProp,ScaleProp)
% Compute common limits for all axes in handle array AX
% All axes are assumed visible.

% Copyright 2020 The MathWorks, Inc.

if(~prod(size(ax)))
    Lmin = NaN;
    Lmax = NaN;
else
    Lims = get(ax(1),LimProp);
    Lmin = Lims(1);
    Lmax = Lims(2);
end

for ct=2:prod(size(ax))
    Lims = get(ax(ct),LimProp);
    Lmin = min(Lmin,Lims(1));
    Lmax = max(Lmax,Lims(2));
end

limits = [Lmin Lmax];
