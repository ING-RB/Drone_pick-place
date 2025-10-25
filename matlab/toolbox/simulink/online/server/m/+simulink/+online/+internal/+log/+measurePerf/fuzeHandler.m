% The fuzehandler handles the exception case that 
% the perfcounter takes much longer time to collect
% data than expected.

% The fuzehander will check if the data json file has
% the desired data or not.

function fuzeHandler(exceptionAction)

    file = dir('*.json');

    if isempty(file)
        eval(exceptionAction);
    else
        dirT = fileread(file.name);
        data = jsondecode(dirT);
        datum = data.updateregions;
        len = length(data);
            
        for idx = 1:len
            line = datum(idx).data;
            if ~isfield(line, 'network')
                eval(exceptionAction);
                break;
            end
        end

    end

end
    