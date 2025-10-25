classdef TabularDataStore < handle
    %TABULARDATASTORE Summary of this class goes here
    %   Detailed explanation goes here
    
    events
        DataChange;
    end
    
    methods (Access='public',Abstract=true)
        [data, dims] = getTabularDataRange(this, startRow, endRow, startColumn, endColumn);
        setTabularDataValue(this, row, column, value);
        [s] = getTabularDataSize(this);
    end
    
end

