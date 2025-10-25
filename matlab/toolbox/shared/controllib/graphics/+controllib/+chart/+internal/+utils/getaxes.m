function propertyValue = getaxes(ax,propertyName)
[nr,nc] = size(ax);
propertyValue = cell(nr,nc);
for kr = 1:nr
    for kc = 1:nc
        propertyValue{kr,kc} = get(ax(kr,kc),propertyName);
    end
end
end