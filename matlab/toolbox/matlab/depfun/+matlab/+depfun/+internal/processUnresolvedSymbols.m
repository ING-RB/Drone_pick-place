function [labeledUnresolved, errors] = processUnresolvedSymbols(unresolvedSymbolMap)
%

%   Copyright 2019-2023 The MathWorks, Inc.

    labeledUnresolved = struct([]);
    errors = {};
    try
        narginchk(1,1);
        
        % Show warnings without stack trace.
        % g3129805 - always warn unresolved undeployable symbols
        orgBacktraceState = warning('backtrace','off');
        restoreWarningState = onCleanup(@()warning(orgBacktraceState));
        
        labeledUnresolved = warnUnresolvedSymbols(unresolvedSymbolMap);
    catch ex
        % The mcc user does not need to see the MATLAB stack trace, so
        % issue a basic report instead of the default, which would be
        % an extended report.
        errors = getReport(ex, 'basic');
    end
    
    function labeledUnresolved = warnUnresolvedSymbols(map)
        labeledUnresolved = struct([]);
        files = keys(map);
        if ~isempty(files)
            % Three categories of unresolved symbols.
            % Category 1: Symbols from undeployable components, 
            %             which are intentionally removed from 
            %             MATLAB search path during compilation.
            % Category 2: Symbols on the search path before compilation 
            %             but not on the search path during compilation.
            % Category 3: Symbols not on the search path or don't exist 
            %             even before compilation.
            
            % There are too many noises in Category 3 due to the
            % limitations of static analysis. Holding off the warning at
            % this point.
            
            % subMsgID = {'MATLAB:depfun:req:UndeployableSymbol' ...
            %             'MATLAB:depfun:req:NotOnPathDuringCompilation' ...
            %             'MATLAB:depfun:req:UnresolvedSymbol'};
            subMsgID = {'MATLAB:depfun:req:UndeployableSymbol' ...
                        'MATLAB:depfun:req:NotOnPathDuringCompilation' };
            num_cat = numel(subMsgID);
            nv = matlab.depfun.internal.requirementsConstants.pcm_nv;

            for f = 1:numel(files)
                cat = cell(1,num_cat);
                for k = 1:num_cat, cat{k} = {}; end
                symbols = map(files{f});
                for s = 1:numel(symbols)
                    w = matlab.depfun.internal.which.callWhich(symbols{s});
                    if isempty(w)
%                         if ~strcmp(symbols{s}, 'deployrc')
%                             cat{3} = [cat{3} symbols{s}];
%                         end
                    else
                        % g2549360 Ignore class methods
                        symbol = matlab.depfun.internal.MatlabSymbol(symbols{s}, ...
                                        matlab.depfun.internal.MatlabType.NotYetKnown, w);
                        determineMatlabType(symbol);
                        if isMethod(symbol) || (~isClass(symbol) && contains(w, matlab.depfun.internal.requirementsConstants.IsABuiltInMethodStr))
                            continue;
                        end

                        symInfo = struct('path', files(f), 'name', symbols(s));
                        compName = nv.componentOwningSymbol(symbols{s});
                        if ~isempty(compName)
                            compInfo = nv.componentInfo(compName);
                            if ~compInfo.IsDeployable
                                cat{1} = [cat{1} symbols{s}];
                                symInfo.reason = 'undeployable';
                            else
                                cat{2} = [cat{2} symbols{s}];
                                symInfo.reason = 'mcc_flag';
                            end
                        else
                            cat{2} = [cat{2} symbols{s}];
                            symInfo.reason = 'mcc_flag';
                        end
                        labeledUnresolved = [labeledUnresolved symInfo]; %#ok
                    end
                end
                
                for k = 1:num_cat
                    if ~isempty(cat{k})
                        warning(message(subMsgID{k}, files{f}, strjoin(cat{k}, ', ')));
                    end
                end 
            end
        end
    end
end

% LocalWords:  undeployable deployrc
