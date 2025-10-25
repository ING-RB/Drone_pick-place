%% Consider mexhost created using following commands and the expected output:
% >> env = ["EnvVariableName1234", "EnvVariableValue1"
%       "EnvVariableName2", "EnvVariableValue234"];
% >> mh = mexhost("EnvironmentVariables",env);
% >> mh.feval("arrayProduct",2,4);
% >> mh.feval("sonnetWordCount");
% >> mh
% mh =
%
%   MexHost with properties:
%
%              ProcessName: "MATLABMexHost"
%        ProcessIdentifier: "22976"
%                Functions: "sonnetWordCount"    "arrayProduct"
%     EnvironmentVariables: "EnvVariableName1234"    "EnvVariableValue1"
%                           "EnvVariableName2"       "EnvVariableValue234"
%%
%  We notice that all properties name end at the same position on display
%  even if they have different length. To achieve this we add left padding
%  to property names. "EnvironmentVariables" is clearly longest string so
%  the padding that we add has to be length(EnvironmentVariables) -
%  length(property). For example in case of Functions

%   EnvironmentVariables:
%   ###########Functions:
%   where # is padding.

%   Similarly while working with values in environment variables starting
%   position of each column should be same to do that we need to add
%   padding on right of shorter strings. For example: "EnvVariableName1234"
%   is longer than "EnvVariableName2" by 3 characters hence we add 3
%   characters padding on "EnvVariableName2". We do the same on second
%   column. Hence in above case actual display will be:
%
%   EnvironmentVariables: "EnvVariableName1234"    "EnvVariableValue1"##
%                         "EnvVariableName2"###    "EnvVariableValue234"
%   where # is the padding.
%
%   If functionsList or Environment variables can not be displayed on the
%   command window due to large size we will just display size of the
%   vector/matrix.
%
%%
function displayScalarObject(obj)
% This is a helper function used while displaying environment
% variables. This function will create environment variable custom
% string with appropriate padding.
    function row = envDisplayHelper(env,i,longest1st, longest2nd)
        row = """" + env(i,1) + """";
        row = pad(row,longest1st+2,"right");
        row = row+"    "';
        row = row+"""" + env(i,2) + """";
        row = pad(row,longest2nd+2,"right");
    end

    % Find all properties of object.
    propNames = properties(obj);
        sp = matlab.internal.display.formatSpacing;

        commandWindowSize = matlab.desktop.commandwindow.size;

        if strcmp(sp,'loose')
            cr = newline;
        else
            cr = '';
        end

        % Don't show stacktrace if warning is generated here.

        warn = warning('backtrace');
        warning ('off', 'backtrace');
        values{1} = obj.ProcessName;
        w = warning('query','last');
        id = "";
        if ~isempty(w)
            id = w.identifier;

            % Process does not exist warning should be shown only once hence disable
            % it.
            if(strcmp(id,'MATLAB:mex:MexHostNonExistingProcess'))
                warning('off',id);
            end
        end

        values{2} = obj.ProcessIdentifier;

        functionsColum = (obj.Functions);

        % Convert function list from column vector to row vector and create
        % string out of it.
        functionsList = functionsColum.';
        functionListJoined = strjoin(functionsList,"""    """);

        % Check if there is enough place to display entire list else just
        % display it's size (which is default for column vector).
        % Here 27 is place required for displaying "Functions:" on the command
        % window.
        if(isempty(functionsList) || (strlength(functionListJoined)+27 > commandWindowSize(1)))
            values{3} = functionsColum;
        else
            values{3} = functionListJoined;
        end
        values{4} = obj.EnvironmentVariables;

        % Restore warning to it's previous state.
        if(strcmp(id,'MATLAB:mex:MexHostNonExistingProcess'))
            warning(w.state,id);
        end

        warning(warn.state, 'backtrace');

        % Get and display class header.
        header = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
        m = message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_SCALAR_WITH_PROPS', header);
        fprintf('  %s%c%c', getString(m), cr, newline);

        % If there are no environment variables to display, we don't have to
        % customize anything.
        if(isempty(values{4}))
            propValues = cell2struct(values,propNames,2); %#ok<NASGU>
            strToDisplay = regexprep(evalc('disp(propValues)'), '''<no value>''' , '<no value>');
            fprintf('%s',strToDisplay);
        else
            % Find first property and it's value.
            s  = propNames{1} + ": "+""""+ values{1}+"""";
            % Add padding for spaces in front.
            s = pad(s,13+strlength(s), "left");
            disp(s);

            % Find second property and it's value.
            s = propNames{2} + ": "+""""+values{2}+"""";

            % Add padding for spaces in front.
            s = pad(s,7+strlength(s), "left");
            disp(s);

            % Find third property and it's values.
            s = propNames{3} + ": ";

            % Add padding before display.
            s = pad(s,15+strlength(s), "left");

            % This is special case if functions list is empty.
            if(isempty(functionsList))
                s = s +  "[0" + char(215) + "0 string]";
                % There is enough place to display list of functions.
            elseif(strlength(functionListJoined+s) <=  commandWindowSize(1))

                functionListJoined = """" + functionListJoined + """";
                s = s+functionListJoined;
                % If there is not enough place just display dimensions.
            else
                n = length(functionsList);
                s = s + "[" + n + char(215) + "×1 string" + "]";
            end
            disp(s);

            env = values{4};
            numRows = size(env,1);
            % To add padding to strings we must know exact value of longest
            % string in each column of environment variable.
            longest1st = strlength(env(1,1));
            longest2nd = strlength(env(1,2));
            for i = 2:numRows
                if(strlength(env(i,1)) > longest1st)
                    longest1st = strlength(env(i,1));
                end
                
                if(strlength(env(i,2)) > longest2nd)
                    longest2nd = strlength(env(i,2));
                end
            end

            for i = i+1:numRows*2
                if(strlength(env(i)) > longest2nd)
                    longest2nd = strlength(env(i));
                end
            end

            % Display environment varialbe
            s = propNames{4} + ": ";
            s = pad(s,4+strlength(s),"left");

            % 9 is because of 4 " + 5 spaces required for display
            % Make sure there is enough place on command window for display
            % else display size.
            if (strlength(s) + 9 + longest1st + longest2nd <= commandWindowSize(1))
                row = envDisplayHelper(env,1,longest1st, longest2nd);

                s = s+row;
                disp(s);

                for i = 2:numRows
                    s="";
                    row = envDisplayHelper(env,i,longest1st, longest2nd);
                    s = s+row;
                    s = pad(s,26+strlength(s),"left");
                    disp(s);
                end
            else
                s = s + "[" + numRows + char(215) + "2 string" + "]";
                disp(s);
            end
            fprintf('\n');
        end
    end
