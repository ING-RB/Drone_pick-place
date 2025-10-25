function tf = isequalImpl(areNansEqual, varargin)
% Implementation for the isequal and isequaln functions for dictionary

%   Copyright 2021-2023 The MathWorks, Inc.
    
    tf = false;
    numInputs = nargin - 1;
    numConfigured = 0;
    allCombinable = true;
    
    for i = 1:numInputs
        d = varargin{i};
        if ~isa(d, 'dictionary')
            return;
        elseif isConfigured(d)
            numConfigured = numConfigured + 1;
            
            if ~matlab.internal.dictionary.isEntryCombinable(d)
                allCombinable = false;
            end
        end
    end

    if numConfigured ~= numInputs
        tf = numConfigured == 0;
        return;
    end
    
    d1 = varargin{1};
    d1KeyType = types(d1);
    d1NumEntries = numEntries(d1);
    for i = 2:numInputs
        d2 = varargin{i};
        
        d2NumEntries = numEntries(d2);
        if d1NumEntries ~= d2NumEntries
            return;
        end
    
        d2KeyType = types(d2);
        if ~matches(d1KeyType, d2KeyType)
            return;
        end
    end
    
    if areNansEqual
        isequalFcn = @(a,b)isequaln(a,b);
    else
        isequalFcn = @(a,b)isequal(a,b);
    end

    if allCombinable
        d1Keys = keys(d1);
        d1Values = values(d1);
        for i = 2:numInputs
            d2 = varargin{i};

            if ~all(isKey(d2, d1Keys), 'all')
                return;
            end

            d2Values = d2(d1Keys);
            if ~isequalFcn(d1Values, d2Values)
                return;
            end
        end
    else
        d1Entries = entries(d1, 'struct');
        for i = 2:numInputs
            d2 = varargin{i};
            
            if ~compareOneDirection(isequalFcn, d1Entries, d2)
                return;
            end
        end
    end
   
    tf = true;
end

function tf = compareOneDirection(isequalFcn, d1Entries, d2)
    
    tf = false;
    for j = 1:numel(d1Entries)
        k = d1Entries(j).Key;

        if ~isKey(d2, k)
            return;
        end
        
        v1 = d1Entries(j).Value;
        v2 = d2(k);
        if ~isequalFcn(v1, v2)
            return;
        end
    end
    tf = true;
end
