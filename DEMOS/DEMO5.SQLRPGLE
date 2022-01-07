000100211015**free
000200211026// This program uses systools.httpgetclob api to request the api.weather.gov alerts
000300211026// for the requested state. It is a work in progress to demo.
000400211018ctl-opt dftactgrp(*no) actgrp('RDI') option( *srcstmt: *nodebugio: *noxref ) ccsid(*CHAR:37);
000500211021
000600211117dcl-c API_WEATHER_GOV 'https://api.weather.gov/alerts/active?area=';
000601211117dcl-c DFTSTATE 'MN';
000602211117dcl-c LF X'25';
000603211117dcl-c NEW_STATE 'Enter a new state, or check back later for events in your state.';
000604211117dcl-c NO_EVENTS_FOUND 'No events found for your state';
000605211117dcl-c SPACE X'40';
000606211117dcl-c SPLAT X'5C';
001300211025
001400211025// This is the file defintion for demo5ds and it's indata area
001500211025dcl-f demo5ds workstn indds(inDS) sfile(SFLREC:EVRRN) usropn;
001600211110
001700211110dcl-pi *n;
001800211110  pState char(2);
001900211110end-pi;
002000211025
002100211117/copy demos,demo5inds
002800211025
002900211020// Get our program name
003000211020dcl-ds pgmDS psds qualified;
003100211020  ProgramName *proc;
003200211020end-ds;
003300211020
003400211015// This is a program call to SYSTOOLS.HTTPGETCLOB to the NOA weather service
003500211015// API https://api.weather.gov/alerts/active?area=MN
003600211019// It will dsply the alerts for FLDSTATE
003700211015
003800211015dcl-ds alerts qualified;
003900211015  event    varchar(256);
004000211015  headline varchar(1024);
004100211015  desc     varchar(1024);
004200211015END-DS;
004300211019
004400211021dcl-ds alertArray likeds(alerts) dim(100);
004500211021dcl-s api char(128);
004600211019dcl-s SBSTATE like(FLDSTATE);
004700211015dcl-s len int(10);
004800211019dcl-s index  int(10);
004900211018dcl-s evSize int(10);
005000211022dcl-s nSize  int(10);
005100211018dcl-s tempVar like(alerts.desc);
005200211021dcl-s STATE char(14) CTDATA Dim(50);
005300211021dcl-s ABBR  char(2)  CTDATA Dim(50);
005400211021dcl-s ind   int(10);
005500211015
005600211021// Initialize
005700211110initialize();
005800211021
005900211021// Set our subfile state
006000211022initSubfileData();
006100211019
006200211020// Load the array with weather events
006300211020loadData();
006400211021
006500211021// Clear the subfile here
006600211021clearSubfile();
006700211018
006800211021// Load the subfile data now
006900211021loadSubfile();
007000211018
007100211021// Set our *IN03 off so our loop works below
007200211021inDS.exit = *off;
007300211021
007400211108// Start of our main program loop. We will
007500211108mainProcess();
007600211108
007700211018
007800211021// Clean up by closing the screen file if it's open
007900211021cleanup();
008000211021
008100211015return;
008200211015
008300211020
008400211020// --------------------------------------------------
008500211020// Procedure name: loadData
008600211020// Purpose:        Load the array with weather events
008700211020// Returns:
008800211020// --------------------------------------------------
008900211020dcl-proc loadData;
009000211020  // Local fields
009100211021  index = 0;
009200211021  clear alertArray;
009300211020
009400211020  // Load the array with weather events
009500211020  // 'https://api.weather.gov/alerts/active?area=CO'
009600211110  Exec Sql
009700211110    Declare Weatherevents Cursor For
009800211021
009900211110      Select X.Event,
010000211110             X.Headline,
010100211110             X.Desc
010200211110        From Json_Table (Systools.Httpgetclob(:Api, Null), '$.features[*]' Columns (
010300211110           Event Char(256) Path '$.properties.event',
010400211110           Headline Char(1024) Path '$.properties.headline',
010500211110           Desc Char(1024) Path '$.properties.description')) As X;
010600211020
010700211110  Exec Sql
010800211110    Open Weatherevents;
010900211020
011000211110  Exec Sql
011100211110    Fetch Next From Weatherevents
011200211110      Into :Alerts;
011300211020
011400211020  dow SQLSTATE = '00000';
011500211020    index = index+1;
011600211022    alertArray(index).event    = alerts.event;
011700211021    alertArray(index).headline = alerts.headline;
011800211022    alertArray(index).desc     = alerts.desc;
011900211110    Exec Sql
012000211110      Fetch Next From Weatherevents
012100211110        Into :Alerts;
012200211123  enddo;
012300211020
012400211110  Exec Sql
012500211110    Close Weatherevents;
012600211020
012700211020  return;
012800211020end-proc;
012900211021
013000211021// --------------------------------------------------
013100211021// Procedure name: loadSubfile
013200211021// Purpose:        Load the subfile data now
013300211021// Returns:
013400211021// --------------------------------------------------
013500211021dcl-proc loadSubfile;
013600211021  // Local fields
013700211021  index = 0;
013800211021
013900211021  // Load the subfile data now
014000211021  dow (index < len);
014100211021    index = index + 1;
014200211022    EVRRN    = index;
014300211022    EVHEADLN = %subst(alertArray(index).headline: 1: nSize);
014400211022    tempVar  = %subst(alertArray(index).desc: 1 : evSize);
014500211021    // Replace all <cr><lf> with spaces
014600211025    tempVar  = %Xlate(LF:SPACE:tempVar);
014700211021    // Now replace * with spaces
014800211022    tempVar  = %Xlate(SPLAT:SPACE:tempVar);
014900211022    // Now trim
015000211022    EVDESC   = %trim(tempVar);
015100211021    write SFLREC;
015200211021  enddo;
015300211021
015400211021  inDs.dsplay = (len > 0);
015500211022  // If we are empty let the user know
015600211022  if (inDs.dsplay = *off);
015700211022    EVRRN = 1;
015800211026    EVHEADLN = NO_EVENTS_FOUND;
015900211026    EVDESC   = NEW_STATE;
016000211022    write SFLREC;
016100211022    inDs.dsplay = *on;
016200211022  endif;
016300211021
016400211021  return;
016500211021end-proc;
016600211021
016700211021// --------------------------------------------------
016800211022// Procedure name: initSubfileData
016900211021// Purpose:        Set our subfile state
017000211021// Returns:
017100211021// --------------------------------------------------
017200211022dcl-proc initSubfileData;
017300211021  // Local fields
017400211021
017500211021  // Set our subfile state
017600211021  SBSTATE = FLDSTATE;
017700211021  ind = %lookup(FLDSTATE: ABBR);
017800211021  if (ind > 0);
017900211021    SFSTATE = STATE(ind);
018000211021  endif;
018100211021  api = '' + API_WEATHER_GOV + SBSTATE + '';
018200211021
018300211021  return;
018400211025end-proc;
018500211021
018600211021// --------------------------------------------------
018700211021// Procedure name: clearSubfile
018800211021// Purpose:        Load the subfile here
018900211021// Returns:
019000211021// --------------------------------------------------
019100211021dcl-proc clearSubfile;
019200211021  // Local fields
019300211021
019400211021  // Load the subfile here
019500211021  inDS.dspctl = *off;
019600211021  inDS.dsplay = *off;
019700211021  write SFLCTRL;
019800211021  inDS.dspctl = *on;
019900211021  len = index;
020000211022
020100211021  return;
020200211021end-proc;
020300211021
020400211021// --------------------------------------------------
020500211021// Procedure name: init
020600211021// Purpose:        Initialize
020700211021// Returns:
020800211021// --------------------------------------------------
020900211110dcl-proc initialize;
021000211021  // Local fields
021100211021
021200211021  // Initialize
021300211021  // Open the display file
021400211021  open demo5ds;
021500211021
021600211021  // Clear the sql control area
021700211021  clear SQLCA;
021800211021
021900211021  // One time settings
022000211021  PGMNAME  = pgmDS.ProgramName;
022100211110  if (pState = '  ');
022200211110    pState = DFTSTATE;
022300211110  endif;
022400211110
022500211110  FLDSTATE = pState;
022600211022  nSize  = %len(EVHEADLN);
022700211022  evSize = %len(EVDESC);
022800211021
022900211021  return;
023000211021end-proc;
023100211021
023200211021// --------------------------------------------------
023300211021// Procedure name: cleanup
023400211021// Purpose:        Clean up by closing the screen file if it's open
023500211021// Returns:
023600211021// --------------------------------------------------
023700211021dcl-proc cleanup;
023800211021  // Local fields
023900211021
024000211021  // Clean up by closing the screen file if it's open
024100211021  if %open(demo5ds);
024200211021    close demo5ds;
024300211021  endif;
024400211021
024500211021  return;
024600211021end-proc;
024700211108
024800211108// --------------------------------------------------
024900211108// Procedure name: mainProcess
025000211108// Purpose:        Start of our main program loop. We will
025100211108// Returns:
025200211108// --------------------------------------------------
025300211108dcl-proc mainProcess;
025400211108  // Local fields
025500211108
025600211108  // Start of our main program loop. We will
025700211108  // loop until *IN03 - exit is encounted.
025800211108  dow (inDS.exit = *off);
025900211108    write FOOTER;
026000211108    exfmt SFLCTRL;
026100211108    if (inDS.refresh = *on OR FLDSTATE <> SBSTATE);
026200211108      // Set our subfile state
026300211108      initSubfileData();
026400211108      // Reload data here
026500211108      loadData();
026600211108
026700211108      // Clear the subfile here
026800211108      clearSubfile();
026900211108
027000211108      // Load the subfile data now
027100211108      loadSubfile();
027200211108
027300211108    endif;
027400211108  enddo;
027500211108
027600211108  return;
027700211108end-proc;
027800211108**CTDATA STATE
027900211019Alabama
028000211019Alaska
028100211019Arizona
028200211019Arkansas
028300211019California
028400211019Colorado
028500211019Conneticut
028600211019Delaware
028700211019Florida
028800211019Georgia
028900211019Hawaii
029000211019Idaho
029100211019Illinois
029200211019Indiana
029300211019Iowa
029400211019Kansas
029500211019Kentucky
029600211019Louisiana
029700211019Maine
029800211019Maryland
029900211019Massachusetts
030000211019Minnesota
030100211019Mississippi
030200211019Missouri
030300211019Montana
030400211019Nebraska
030500211019Nevada
030600211019New Hampshire
030700211019New Jersey
030800211019New Mexico
030900211019New York
031000211019North Carolina
031100211019North Dakota
031200211019Ohio
031300211019Oklahoma
031400211019Oregon
031500211019Pennsylvania
031600211019Rhode Island
031700211019South Carolina
031800211019South Dakota
031900211019Tennessee
032000211019Texas
032100211019Utah
032200211019Vermont
032300211019Virginia
032400211019Washington
032500211019West Virginia
032600211019Wisconsin
032700211019Wyoming
032800211019**CTDATA ABBR
032900211019AL
033000211019AK
033100211019AZ
033200211019AR
033300211019CA
033400211019CO
033500211019CT
033600211019DE
033700211019FL
033800211019GA
033900211019HI
034000211019ID
034100211019IL
034200211019IN
034300211019IA
034400211019KS
034500211019KY
034600211019LA
034700211019ME
034800211019MD
034900211019MA
035000211019MN
035100211019MS
035200211019MO
035300211019MT
035400211019NE
035500211019NV
035600211019NH
035700211019NJ
035800211019NM
035900211019NY
036000211019NC
036100211019ND
036200211019OH
036300211019OK
036400211019OR
036500211019PA
036600211019RI
036700211019SC
036800211019SD
036900211019TN
037000211019TX
037100211019UT
037200211019VT
037300211019VA
037400211019WA
037500211019WV
037600211019WI
037700211019WY
