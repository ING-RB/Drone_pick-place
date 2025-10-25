function outLayout = keyboard(varargin)
% KEYBOARD Set keyboard layout in Simulink Online.
%     PREVLAYOUT = keyboard(NEWLAYOUT) sets NEWLAYOUT as the keyboard layout
%     for Simulink Online and returns PREVLAYOUT as the previous keyboard
%     layout. NEWLAYOUT must be one of the supported keyboard layout names
%     listed below.
%
%     CURRENT = keyboard() returns the current keyboard layout as CURRENT.
%     The default keyboard layout is 'us'. In some cases, Simulink Online
%     can auto-detect keyboard layout and in those cases the default
%     keyboard layout will be set to the auto-detected keyboard layout.
%     Setting keyboard layout using this function will override the
%     auto-detected keyboard layout and will use the setting provided in
%     this function.
%
%     Example:
%
%     previousLayout = simulink.online.keyboard('jp');
%     The example above will set the keyboard layout to Japanese and return
%     'us' as the previousLayout which is the default.
%
%     currentLayout = simulink.online.keyboard();
%     The example above will return the current layout in currentLayout.
%
%     Supported layouts:
%       us                English (US)
%       us.intl           English (US, international)
%       af                Afghani
%       ara               Arabic
%       al                Albanian
%       am                Armenian
%       at                German (Austria)
%       au                English (Australian)
%       az                Azerbaijani
%       by                Belarusian
%       be                Belgian
%       bd                Bangla
%       in                Indian
%       ba                Bosnian
%       br                Portuguese (Brazil)
%       bg                Bulgarian
%       dz                Berber (Algeria, Latin characters)
%       ma                Arabic (Morocco)
%       cm                English (Cameroon)
%       mm                Burmese
%       ca                French (Canada)
%       cd                French (Democratic Republic of the Congo)
%       cn                Chinese
%       hr                Croatian
%       cz                Czech
%       dk                Danish
%       nl                Dutch
%       bt                Dzongkha
%       ee                Estonian
%       ir                Persian
%       iq                Iraqi
%       fo                Faroese
%       fi                Finnish
%       fr                French
%       gh                English (Ghana)
%       gn                French (Guinea)
%       ge                Georgian
%       de                German
%       gr                Greek
%       hu                Hungarian
%       is                Icelandic
%       il                Hebrew
%       it                Italian
%       jp                Japanese
%       kg                Kyrgyz
%       kh                Khmer (Cambodia)
%       kz                Kazakh
%       la                Lao
%       latam             Spanish (Latin American)
%       lt                Lithuanian
%       lv                Latvian
%       mao               Maori
%       me                Montenegrin
%       mk                Macedonian
%       mt                Maltese
%       mn                Mongolian
%       no                Norwegian
%       pl                Polish
%       pt                Portuguese
%       ro                Romanian
%       ru                Russian
%       rs                Serbian
%       si                Slovenian
%       sk                Slovak
%       es                Spanish
%       se                Swedish
%       ch                German (Switzerland)
%       sy                Arabic (Syria)
%       tj                Tajik
%       lk                Sinhala (phonetic)
%       th                Thai
%       tr                Turkish
%       tw                Taiwanese
%       ua                Ukrainian
%       gb                English (UK)
%       uz                Uzbek
%       vn                Vietnamese
%       kr                Korean
%       nec_vndr/jp       Japanese (PC-98xx Series)
%       ie                Irish
%       pk                Urdu (Pakistan)
%       mv                Dhivehi
%       za                English (South Africa)
%       epo               Esperanto
%       np                Nepali
%       ng                English (Nigeria)
%       et                Amharic
%       sn                Wolof
%       brai              Braille
%       tm                Turkmen
%       ml                Bambara
%       tz                Swahili (Tanzania)
%       tg                French (Togo)
%       ke                Swahili (Kenya)
%       bw                Tswana
%       ph                Filipino
%       md                Moldavian
%       id                Indonesian (Jawi)
%       my                Malay (Jawi)
%       bn                Malay (Jawi) 
% 
%     Copyright 2021 The MathWorks, Inc.

outLayout = simulink.online.internal.keyboard.get();

if nargin == 1
    simulink.online.internal.keyboard.set(varargin{1});
end