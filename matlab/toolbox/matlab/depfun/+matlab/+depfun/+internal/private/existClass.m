function tf = existClass(nm)    
% Does meta.class.fromName know about it?

%   Copyright 2013-2020 The MathWorks, Inc.

    tf = false;
    try
        metadata = meta.class.fromName(nm);
        if ~isempty(metadata)
            tf = true;
        elseif matlab.depfun.internal.cacheExist(nm,'class') == 8
            % Does exist think it is a class?
            tf = true;
        end
    catch
        % ignore the nonsense thrown out from meta.class.fromName
    end
end
