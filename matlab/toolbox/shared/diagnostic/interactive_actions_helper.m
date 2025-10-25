classdef interactive_actions_helper < handle
   %---------------------- Static Private Methods ------------------------

%   Copyright 2017-2023 The MathWorks, Inc.

    methods (Static = true, Hidden = true, Access = 'public')
      function aPrunedCallback = pruneCbTypeIdentifier(aCallback)
         aPrunedCallback = regexprep(aCallback, '^matlab:', '');
         aPrunedCallback = regexprep(aPrunedCallback, '%5c', '\');
         aPrunedCallback = strtrim(aPrunedCallback);
      end

      function result = applyIntArgVaues(aCallback, aIntArgValues, aIntArgNames)
         result = aCallback;
         for i = 1:length(aIntArgValues)
            result = strrep(result, aIntArgNames{i}, aIntArgValues{i});
         end
      end

      function result = isProtectedFile(aFileName)
          [~, ~, ext] = fileparts(aFileName);
          if (strcmp(ext, ".m") || ...
              strcmp(ext, ".ssc") || ...
              strcmp(ext, ".mlx"))
              result = false; %#ok<NASGU>
              return;
          end
          result = true;
      end

      function displayMStack(aCallback)
          fprintf(2, message('SL_SERVICES:utils:DisplayStack').getString);
          aline = "line " + aCallback(1).line;
          display_string = aCallback(1).name;
          [~,aFileName,~] = fileparts(aCallback(1).file);
          errorUsinglocalString = message('SL_SERVICES:utils:ErrorUsing').getString;

          if (interactive_actions_helper.isProtectedFile(aCallback(1).file))
              fprintf(2,'%s %s\n',errorUsinglocalString, display_string);
          else
              fprintf(2,'%s <a href="matlab:matlab.lang.internal.introspective.errorDocCallback(''%s'',''%s'',%d)">%s</a> ',errorUsinglocalString,display_string,aCallback(1).file,aCallback(1).line,display_string);
              fprintf(2,'(<a href="matlab:opentoline(''%s'',%d)">%s</a>)\n', aCallback(1).file,aCallback(1).line,aline);
          end

          if(length(aCallback) > 1)
              for i=1:length(aCallback)
                  aline = "line " + aCallback(i).line;
                  display_string = aCallback(i).name;
                  [~,aFileName,~] = fileparts(aCallback(i).file);
                  protected_file_string = message('SL_SERVICES:utils:ErrorInLine', display_string).getString;
                  non_protected_file_string = message('SL_SERVICES:utils:ErrorInLine', '<a href="matlab:matlab.lang.internal.introspective.errorDocCallback(''%s'',''%s'',%d)">%s</a> ').getString;

                  %TopTester: matlab/test/toolbox/simulink/slmsgviewer/diagnosticviewer/tMStack.m -testspec:mStackCommandLine
                  if (interactive_actions_helper.isProtectedFile(aCallback(i).file))
                      fprintf(2,'\t   \x2022 %s\n',protected_file_string);
                  else
                      fprintf(2,['\t   \x2022 ', non_protected_file_string], display_string,aCallback(i).file,aCallback(i).line,display_string);
                      fprintf(2,'(<a href="matlab:opentoline(''%s'',%d)">%s</a>)\n', aCallback(i).file,aCallback(i).line,aline);
                  end
              end
          end
      end

      function  reportSuccess()
      %   fprintf(1,strcat(message('SL_SERVICES:utils:FixedString').getString, "\n"));
      end

      function result = applyUserInputsInteractiveActions(aCmd, aIntArgData)
         aCmd = interactive_actions_helper.pruneCbTypeIdentifier(aCmd);
         int_arg_values = [];
         int_arg_names = [];
         for i=1:length(aIntArgData)
            curIntArgData = aIntArgData(i);
            curArgVal = [];
            if (curIntArgData.isMultipleChoice)
               disp (strcat(curIntArgData.prompt, " "));
               for choice_index = 1:length(curIntArgData.options)
                  disp(strcat(num2str(choice_index), ". " ,curIntArgData.options(choice_index)));
               end
               while(true)
                  try
                     inpString = strcat(message('SL_SERVICES:utils:TypeChoice').getString, " ");
                     defValue = curIntArgData.default;
                     if isempty(defValue)
                        defValue = '1';
                     else
                        inpString = strcat(inpString, "[", defValue, "] ");
                     end
                     choice = input(char(inpString));
                     if isempty(choice)
                        choice = str2num(defValue);
                        if isempty(choice)
                            choice = 1;
                        end
                     end
                     curArgVal = curIntArgData.options(choice);
                     break;
                  catch exc
                     fprintf(2,strcat(message('SL_SERVICES:utils:InvalidChoice').getString, "\n"));
                  end
               end
            else
               inpString = strcat(curIntArgData.prompt, " ");
               defValue = curIntArgData.default;

               emptyDefValue = ( strlength( defValue ) == 0 );

               if ~emptyDefValue
                    inpString = strcat(inpString, "[", defValue, "] ");
               end

               while( true )
                   curArgVal = input(char(inpString), 's');

                   if( or( ~emptyDefValue, ~isempty( curArgVal ) ) )
                       break;
                   end

                   fprintf(2,strcat(message('SL_SERVICES:utils:InputMissing').getString, "\n"));
               end

               if isempty(curArgVal)
                    curArgVal = defValue;
               end

            end

            int_arg_values = [int_arg_values string(curArgVal)];
            int_arg_names = [int_arg_names curIntArgData.name];

         end

         result = interactive_actions_helper.applyIntArgVaues(aCmd, int_arg_values, int_arg_names);

      end
	end
end
