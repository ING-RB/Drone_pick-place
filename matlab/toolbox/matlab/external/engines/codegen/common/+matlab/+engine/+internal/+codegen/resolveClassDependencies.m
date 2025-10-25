function [sortedClasses, externalDependencies, dependants] = resolveClassDependencies(classes, funcs, reportObj)
%RESOLVEDEPENDENCIES Resolves dependencies via sorting
% Resolves class dependencies using a DAG. Also determines external
% dependencies and records missing classes.

%   Copyright 2020-2023 The MathWorks, Inc.

    arguments
        classes (1,:) matlab.engine.internal.codegen.ClassTpl
        funcs (1,:) matlab.engine.internal.codegen.FunctionTpl
        reportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
    end
    
    import matlab.engine.internal.codegen.*
    
    dg = digraph();
    localClasses = [];
    tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();

    % Add local classes to the graph in original order
    for i = 1 : length(classes)
        c = classes(i);
        localClasses = [localClasses c.FullClass];
        dg = dg.addnode(c.FullClass);
    end
    
    % Add the edges to the graph
    for i = 1 : length(classes)
        c = classes(i);
        for d = c.Dependencies
            dg = dg.addedge(d, c.FullClass);
        end
    end
    
    %plot(dg)
    
    % Perform the sorting. Also determine external dependencies.
    % First confirm graph is acyclic
    if(hascycles(dg))
        
        cycles = allcycles(dg);
        msg = "";
        for i = 1:length(cycles)
            msg = msg + newline + strjoin(string(cycles{i}));
        end
        
        messageObj = message("MATLAB:engine_codegen:CircularClassDependencies", msg);
        error(messageObj);

    end
    N = dg.toposort;
    
    sortedClasses = matlab.engine.internal.codegen.ClassTpl.empty();
    externalDependencies = string.empty();
    dependants = [];
    
    endnodes = string(dg.Edges.EndNodes);

    for i = 1 : length(N)
       
       % Put class in right order if it is local
       if(N(i) <= length(localClasses))
           sortedClasses = [sortedClasses classes(N(i))];
           
       else  % dependency is external
           dependency = string(dg.Nodes.Name(N(i)));
           % Filter out dependencies on simple supported types and MathWorks authored code
           if(sum(string(tc.ConversionTable.MATLABType).matches(dependency)) == 0 && ~tc.isMathWorksRestricted(dependency))
               % Add dependency
               externalDependencies = [externalDependencies dependency];

               % Note dependants which depend on the dependency
               index = find(endnodes==dependency);
               offset = length(endnodes(:,1));
               index = index + offset; % offset to dependant
               index = index(index <= numel(endnodes)); % ignore out of range cases
               dependants = cat(2, dependants, {endnodes(index)'});
           end
       end

    end

    if( length(sortedClasses) ~= length(classes) )
        % Logic Error: number of classes pre-sort is not equal to number of classes post-sort
        messageObj = message("MATLAB:engine_codegen:InternalLogicError");
        error(messageObj);
    end

    % Determine any unresolved function dependencies on classes
    % Note: No sorting of functions needed since they are generated after classes
    if(~isempty(funcs))
        tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();
        classNames = [""];
        if(~isempty(classes))
            classNames = string([classes.FullClass]);
        end

        % Find unresolved external dependencies
        for n = 1:length(funcs)
            f = funcs(n);
            fname = f.SectionName;
            dependencies = [];
            args = [f.InputArgs, f.OutputArgs]; % Both input and output args might depend on other generated classes
            for arg = args
                mclass = arg.MATLABArrayInfo.ClassName;
                % Remove warning if the class is dictionary as it is a
                % built in
                if(~isempty(char(mclass)) && mclass~="dictionary")
                    dependencies = [dependencies mclass];
                end
            end

            for dependency = dependencies
                if(sum(classNames == dependency) == 0) % Not in provided classes
                    if(sum(string(tc.ConversionTable.MATLABType).matches(dependency)) == 0 && ~tc.isMathWorksRestricted(dependency)) % Not external or MW class
                        if(sum(externalDependencies == dependency)==0) % Add dependency if it has not been added already
                            externalDependencies = [externalDependencies dependency];
                            dependants = cat(2, dependants, {fname});
                        else
                            % Dependency already in list so add dependant if unique
                            index = find(externalDependencies == dependency);
                            if(sum(dependants{index} == dependency) == 0)
                                dependants{index} = [dependants{index} dependency];
                            end
                        end
                    end
                end
            end
        end
    end

    % Find any unresolved dependencies on classes
    if(~isempty(externalDependencies))
        dependants = dependants(externalDependencies~="");
        externalDependencies = externalDependencies(externalDependencies~="");
        dependants = dependants(externalDependencies~="unknown");
        externalDependencies = externalDependencies(externalDependencies~="unknown");
    end

    % Record the missing dependencies and their dependants
    if(~isempty(externalDependencies))

        if( length(externalDependencies) ~= length(dependants) )
            % Logic Error: Each dependency should have more than zero dependants
            messageObj = message("MATLAB:engine_codegen:InternalLogicError");
            error(messageObj);
        end

        missingClasses = [];
        for i = 1:length(externalDependencies)
            md = matlab.engine.internal.codegen.reporting.MissingDependency(externalDependencies(i), dependants{i});
            missingClasses = [missingClasses md];
        end

        reportObj.Missing = missingClasses;

    end

end

