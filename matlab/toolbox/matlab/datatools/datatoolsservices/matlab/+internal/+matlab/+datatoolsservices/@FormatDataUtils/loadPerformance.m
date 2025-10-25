% Setups performance

% Copyright 2015-2023 The MathWorks, Inc.

function loadPerformance(es)
    if strcmp(es.eventType,'VELoadPerformance')
        % milliseconds to seconds
        time = es.loadTime/1000;
        rowCount = es.rows;
        columnCount = es.columns;
        [str,maxsize,endian] = computer;
        type = '';
        fileID = '';

        if strcmp(es.dataType,'variableeditor.views.NumericArrayView')
            type = 'Numerics';
            fileID = fopen('//mathworks/inside/files/dev/ltc/datatools_team/MOPerformance/LoadTimePerformanceNumerics.txt','wt');
        elseif strcmp(es.dataType,'variableeditor.views.TableArrayView')
            type = 'Tables';
            fileID = fopen('//mathworks/inside/files/dev/ltc/datatools_team/MOPerformance/LoadTimePerformanceTables.txt','wt');
        elseif strcmp(es.dataType,'variableeditor.views.CellArrayView')
            type = 'Cell Arrays';
            fileID = fopen('//mathworks/inside/files/dev/ltc/datatools_team/MOPerformance/LoadTimePerformanceCellArrays.txt','wt');
        end

        TIMES_SYMBOL = internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL;
        fprintf(fileID,'%d %s %d %s Load Time : %f seconds\n', rowCount, TIMES_SYMBOL, columnCount, type, time);
        fprintf(fileID,'Platform : %s\n Maximum Size : %d\n Endian : %s\n Operating System : %s\n',str, maxsize, endian, getenv('OS'));
        fprintf(fileID,'Last Updated on : %s\n', char(datetime('now')));

        % close the file
        if ~isempty(fileID)
            fclose(fileID);
        end
    end
end
