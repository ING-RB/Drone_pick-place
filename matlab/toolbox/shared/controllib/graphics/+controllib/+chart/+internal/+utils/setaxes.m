function setaxes(ax,propertyName,propertyValue)
[nr,nc] = size(ax);
if ~iscell(propertyValue)
    propertyValue = {propertyValue};
end
if isscalar(propertyValue)
    propertyValue = repmat(propertyValue,nr,nc);
end

if isequal(size(ax),size(propertyValue))
    for kr = 1:nr
        for kc = 1:nc
            set(ax(kr,kc),propertyName,propertyValue{kr,kc});
        end
    end
end
end