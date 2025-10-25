function layouts = supportedLayouts()
%EXPECTEDKEYBOARDS gets supported keyboard layouts for Simulink Online.
%   layouts = simulink.online.supportedKeyboards() returns the supported
%   keyboard layouts
%
%
%   Expected layout | Country
%   us                English (US)
%   us.intl           English (US, international)
%   af                Afghani
%   ara               Arabic
%   al                Albanian
%   am                Armenian
%   at                German (Austria)
%   au                English (Australian)
%   az                Azerbaijani
%   by                Belarusian
%   be                Belgian
%   bd                Bangla
%   in                Indian
%   ba                Bosnian
%   br                Portuguese (Brazil)
%   bg                Bulgarian
%   dz                Berber (Algeria, Latin characters)
%   ma                Arabic (Morocco)
%   cm                English (Cameroon)
%   mm                Burmese
%   ca                French (Canada)
%   cd                French (Democratic Republic of the Congo)
%   cn                Chinese
%   hr                Croatian
%   cz                Czech
%   dk                Danish
%   nl                Dutch
%   bt                Dzongkha
%   ee                Estonian
%   ir                Persian
%   iq                Iraqi
%   fo                Faroese
%   fi                Finnish
%   fr                French
%   gh                English (Ghana)
%   gn                French (Guinea)
%   ge                Georgian
%   de                German
%   gr                Greek
%   hu                Hungarian
%   is                Icelandic
%   il                Hebrew
%   it                Italian
%   jp                Japanese
%   kg                Kyrgyz
%   kh                Khmer (Cambodia)
%   kz                Kazakh
%   la                Lao
%   latam             Spanish (Latin American)
%   lt                Lithuanian
%   lv                Latvian
%   mao               Maori
%   me                Montenegrin
%   mk                Macedonian
%   mt                Maltese
%   mn                Mongolian
%   no                Norwegian
%   pl                Polish
%   pt                Portuguese
%   ro                Romanian
%   ru                Russian
%   rs                Serbian
%   si                Slovenian
%   sk                Slovak
%   es                Spanish
%   se                Swedish
%   ch                German (Switzerland)
%   sy                Arabic (Syria)
%   tj                Tajik
%   lk                Sinhala (phonetic)
%   th                Thai
%   tr                Turkish
%   tw                Taiwanese
%   ua                Ukrainian
%   gb                English (UK)
%   uz                Uzbek
%   vn                Vietnamese
%   kr                Korean
%   nec_vndr/jp       Japanese (PC-98xx Series)
%   ie                Irish
%   pk                Urdu (Pakistan)
%   mv                Dhivehi
%   za                English (South Africa)
%   epo               Esperanto
%   np                Nepali
%   ng                English (Nigeria)
%   et                Amharic
%   sn                Wolof
%   brai              Braille
%   tm                Turkmen
%   ml                Bambara
%   tz                Swahili (Tanzania)
%   tg                French (Togo)
%   ke                Swahili (Kenya)
%   bw                Tswana
%   ph                Filipino
%   md                Moldavian
%   id                Indonesian (Jawi)
%   my                Malay (Jawi)
%   bn                Malay (Jawi) 

% Copyright 2021 The MathWorks, Inc.

layouts = {'us', 'us.intl', 'af', 'ara', 'al', 'am', 'at', 'au', 'az', ...
    'by', 'be', 'in', 'ba', 'br', 'bg', 'dz', 'ma', 'cm', 'mm', 'ca', ...
    'cd', 'cn', 'hr', 'cz', 'dk', 'nl', 'bt', 'ee', 'ir', 'iq', 'fo', ...
    'fi', 'fr', 'gh', 'gn', 'ge', 'de', 'gr', 'hu', 'is', 'il', 'it', ...
    'jp', 'kg', 'kh', 'kz', 'la', 'latam', 'lt', 'lv', 'mao', 'me', 'mk', ...
    'mt', 'mn', 'no', 'pl', 'pt', 'ro', 'ru', 'rs', 'si', 'sk', 'es', ...
    'se', 'ch', 'sy', 'tj', 'lk', 'th', 'tr', 'tw', 'ua', 'gb', 'uz', ...
    'vn', 'kr', 'nec_vndr/jp', 'ie', 'pk', 'mv', 'za', 'epo', 'np', ...
    'ng', 'et', 'sn', 'brai', 'tm', 'ml', 'tz', 'tg', 'ke', 'bw', ...
    'ph', 'md', 'id', 'my', 'bn'};
end