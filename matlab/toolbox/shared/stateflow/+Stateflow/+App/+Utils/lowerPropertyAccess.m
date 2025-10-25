function [validationPassed, stringToEval] = lowerPropertyAccess(chartName, newDataValueExpr, instanceName )
%

%   Copyright 2019 The MathWorks, Inc.
   %@todo navdeep conditional breakpoint will reach here
   validationPassed = false;    
    try
        chartH = sf('IdToHandle',sfprivate('block2chart', [chartName '/' chartName]));
        stringToEval = newDataValueExpr;
        mt = mtree(stringToEval);
        identifiers = mtfind(mt, 'Kind', 'ID');
        persistentNode = mtfind(mt, 'Kind', 'PERSISTENT');
        persistentVars = List(Arg(persistentNode));
        persistentVarsUses = mt.mtfind('SameID', persistentVars);
        identifiers = identifiers - persistentVarsUses;
        
        strs = strings(identifiers);
        left = lefttreepos(identifiers);
        right = righttreepos(identifiers);
        
        for j = length(strs):-1:1
            usedName = strs{j};
            dataH = chartH.find('-isa', 'Stateflow.Data', 'Name', usedName);
            if ~isempty(dataH)
                stringToEval = [stringToEval(1:left(j)-1) instanceName '.' usedName stringToEval(right(j)+1:end)];
            end
        end
        validationPassed = true;
    catch
        stringToEval = newDataValueExpr;
    end
end
