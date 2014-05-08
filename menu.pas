/////////////////////////////////////////////////////////////////////////
// project   : bbs_cgi
// author    : Ralph Berger
// file      : menu.pas
// erstellt  : 28.02.14
// modified  : RB - 21.03.2014
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
// tested    : yes

unit Menu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, synacode, FmtBCD, mysql55conn, sqldb, blowcryp, mapping ;

CONST
   PageItems = 5;
   cgiPath = '/fcgi-bin/bbs/';
   err_page= 'bbs_error.html';
   MenuS_1 = '<li class="active"><a href="./main?%%0"> TeamBBS Forum </a></li>';
   MenuS_1i= '<li><a href="./main?%%0"> TeamBBS Forum </a></li>';
   MenuS_2 = '<li><a href="' + cgiPath + 'quit?%%0"> Abmelden </a></li>' +
             '<li><a href="' + cgiPath + 'upst?%%0"> Meine Nachrichten </a></li>';

   FootStr = '<ul id="footer_menu">' +
             '<li class="homeButton">' +
             '<a href="http://www.bergertime.de"></a>' +
             '</li>' +
             '<li>' +
             '<a>BBS</a>' +
             '<div class="one_column_layout">' +
             '<div class="col_1">' +
             '<a class="headerLinks">Mitmachen</a></p>' +
             '<a href="https://www.bergertime.eu/bbs_style.pdf" class="listLinks">Styles</a>' +
             '<a href="https://www.bergertime.eu/bbs_cgi.pdf" class="listLinks">CGIs</a>' +
             '<a href="https://www.bergertime.eu/bbs_help.pdf" class="listLinks">Hilfe</a>' +
             '<a class="headerLinks">Information</a></p>' +
             '<a href="' + cgiPath + 'legal?actn=1%%0" class="listLinks">AGBs</a>' +
             '<a href="' + cgiPath + 'legal?actn=2%%0" class="listLinks">Datenschutz</a>' +
             '<a href="' + cgiPath + 'legal?actn=3%%0" class="listLinks">Impressum</a>' +
             '</div></div></li><li>' +
             '<a>Ansicht</a>' +
             '<div class="one_column_layout">' +
             '<div class="col_1">' +
             '<a class="headerLinks">Sortiert nach</a>' +
             '</p>';
   FootHigh= 'style="font-weight:bold;color:white;"'  ;

   accntErr= '<div class="form-title"><BR>Account Info:<BR><BR>%%1<BR><BR>%%2<BR></div>' +
             '<div class="submit-container"><a href=javascript:history.back()><img src="../../ok.png" alt="OK" id="ID_OK" /></a></div>';

   accntEdt= '<div class="bulp_right"><img src="%%5"></div>' +
             '<div class="form-title"><h3>Ihr Benutzerkonto</h3></div>' +
             '<div class="form-title">Benutzername</div>' +
             '<input class="form-field" name="usr_name" type="text" value ="%%1" required="required" placeholder="Benutzername"><br>' +
             '<div class="form-title">eMail</div>' +
             '<input class="form-field" name="email" type="email" value ="%%2" required="required" placeholder="user@gmail.com"><br>' +
             '<div class="form-title">Passwort</div>' +
             '<input class="form-field" name="password" value ="%%3" required="required" type="password">' +
             '<div class="form-title">Passwort bestätigen</div>' +
             '<input class="form-field" name="password_confirm" value ="%%4" required="required" type="password"><br>' +
             '<div class="form-title">Photo</div>'+
             '<input class="form-field" name="bild" type="file" value="Photo (PNG 64 x 64 Pixel)"><br>' +
             '<input type="checkbox" name="vsbl" %%6>andere Nutzer dürfen mir Nachrichten senden<br><br>' +
             '<input type="checkbox" name="agb" checked ="true" required="required">Ich stimme den Nutzungsbedingungen zu<br>' +
             '<div class="submit-container"><input class="submit-button" name="submit" type="submit" value="Speichern"></div>' +
             '<input type="hidden" name="sesn" id="sesn" value="%%7">';

   usrTbl = '<div class="fItem">' +
           '<table>' +
           '<tbody>' +
           '<tr>' +
             '<td width="80px">' +
               '<img src="%%0" class="usr-image">' +
              '</td>' +
	      '<td>Themen: %%1 - Antworten: %%2 </td>' +
           '</tr>' +
           '</tbody>' +
           '</table>' +
           '</div>' +
           '<div class="clear"></div>';
  tpcTbl = '</p>' +
            '<div class="fItem" style="left: 3%; width:92%;">' +
            '<table>' +
            '<tbody>' +
            '<tr>' +
              '<td>Thema %%3 vom: %%4</td>' +
            '</tr>' +
            '<tr>' +
            '<td>' +
            '<textarea class="ckeditor" name="S1" id="S1" width="100%">%%5</textarea>' +
              '<script>' +
  		'CKEDITOR.config.readOnly = true;' +
   		'CKEDITOR.config.resize_dir = ''both'';' +
                'CKEDITOR.config.toolbarStartupExpanded = false;' +
                'CKEDITOR.config.toolbarCanCollapse = true;' +
                'CKEDITOR.config.height = ''80px'';' +
              '</script>' +
            '</td>' +
            '</tr>' +
            '</tbody>' +
            '</table>' +
            '</div>' +
            '<div class="clear"></div>';

   delPst = '<div class="fItem">' +
            '<table><tbody><tr>' +
            '<td>Gelöscht wird die Antwort von: %%1 am: %%2</td>' +
  	    '<td rowspan="3" width=25%%><img src="%%6" class="usr-image"><BR>%%7</td>' +
	    '</tr><tr><td><textarea class="ckeditor" name="S2" id="S2" width="100%">%%3</textarea>' +
            '<script>' +
   		'CKEDITOR.replace(''S2'');' +
  		'CKEDITOR.config.readOnly = true;' +
   		'CKEDITOR.config.resize_dir = ''both'';' +
            '</script>' +
            '</td></tr><tr><td>' +
            '<form method="POST" action="' + cgiPath + 'change">' +
            '<input type="hidden" value="%%4" name="ID">' +
            '<input type="hidden" value="%%5" name="sesn">' +
            '<button name="B4" value="deltpst">Löschen</button>' +
	    '</form></td></tr></tbody></table>' +
            '<BR></div><div class="clear"></div><br>';


   pstTbl = '<div class="fItem" style="left: 6%; width:89%;">' +
            '<table>' +
            '<tbody>' +
            '<tr>' +
              '<td>Antwort am: %%6 </td>' +
            '</tr>' +
            '<tr>' +
            '<td>' +
            '<textarea class="ckeditor" name="S2" id="S2" width="100%">%%7</textarea>' +
              '<script>' +
  		'CKEDITOR.config.readOnly = true;' +
   		'CKEDITOR.config.resize_dir = ''both'';' +
                'CKEDITOR.config.toolbarStartupExpanded = false;' +
                'CKEDITOR.config.toolbarCanCollapse = true;' +
                'CKEDITOR.config.height = ''80px'';' +
              '</script>' +
            '</td>' +
            '</tr>' +
            '</tbody>' +
            '</table>' +
            '</div>' +
            '<div class="clear"></div>';
   usrTile= '<a href="' + cgiPath + 'upst?ID=%%0&sesn=%%6" class="%%1">%%2' +
            '<br>&nbsp;' +
            '<img src="%%3" alt="User" class="usr-img">' +
            '<small><p>' +
            '<img src="/../nachricht.png" title="Angemeldet seit" alt="Logon time">%%4&nbsp;' +
            '<img src="/../flash.png" title="Anmelungen" alt="views">%%5' +
            '</p></small></a>';
   tpcTile= '<a href="%%6" class="%%1">' +
            '%%2<br><br><small>%%3<br><br><img src="/../nachricht.png" alt="last post">' +
            '&nbsp;%%4&nbsp;<img src="/../count.png" alt="views">&nbsp;%%5</small></a>';

   findinfo='<tr>' +
    	      '<td colspan="4">Suche nach Überschrift: <B>%%5</B> Autor: <B>%%6</B> Datum: <B>%%7</B> Text: <B>%%8</B></td>' +
            '</tr>';

   findrslt='<tr>' +
               '<td>%%1</td>' +
    	       '<td>%%2</td>' +
    	       '<td>%%3</td>' +
    	       '<td>%%4</td>' +
            '</tr>';

   newsinfo='<tr>' +
    	      '<td colspan="4">Neue Nachrichten seit: <B>%%5</B></td>' +
            '</tr>';

   function showUsrImage( CONST usrFrm:usrInfType ): String;
   function showUsrInfo ( CONST usrFrm:usrInfType ): String;
   function make_Header       ( CONST myPara:paraType ): String;
   function make_Header_newThm( CONST myPara:paraType ): String;
   function make_Header_Forum ( CONST myPara:paraType ): String;
   function make_Header_Posts ( CONST myPara:paraType ): String;
   function make_Header_UPosts( CONST myPara:paraType ): String;
   function make_Header_APosts( CONST myPara:paraType ): String;
   function make_Header_Accnt ( CONST myPara:paraType ): String;
   procedure paraTypeInit( CONST sTgt: String ; VAR myPara:paraType );
   procedure sesn_copy_para( Var mySessn:sessInfType; VAR myPara:paraType );
   function make_Footer( CONST conn: TMySQL55Connection; CONST myPara:paraType ): String;


implementation


procedure sesn_copy_para( Var mySessn:sessInfType; VAR myPara:paraType );
begin
  if leftstr(mySessn.forwarded_for, 4) = leftstr(myPara.Text1, 4) then
     begin
       myPara.v_page  := mySessn.v_page;   // from session settings
       myPara.v_rec   := mySessn.v_rec;
       myPara.v_order := mySessn.v_order;
       myPara.v_eof   := mySessn.v_eof;
     end
   else
     begin
       myPara.v_page  := '0';              // no page - reset to defaults
       myPara.v_rec   := '1';
       myPara.v_order := '1';
       myPara.v_eof   := '0';
     end;
end;

procedure paraTypeInit( CONST sTgt: String ; VAR myPara:paraType );
begin
 myPara.Text1   := sTgt ;        // callback target for event handler
 myPara.v_page  := '0';          // defaults
 myPara.v_rec   := '1';
 myPara.v_order := '1';
 myPara.v_eof   := '0';
end;



function showUsrInfo( CONST usrFrm:usrInfType ): String;
begin
  showUsrInfo := '<BR><BR><small>' +
                 'Benutzer: ' + usrFrm.Name + '<BR>' +
                 'Besuche: '  + usrFrm.TotalTime + '<BR>' +
                 'seit: '     + LEFTSTR( usrFrm.RegisterTime,10 ) + '<BR></small>';
end;

///////////////////////////////////////////////
// task    read usr image
// normalize user display
// retuns  base64 encoded string form blob or link to empty.png
function showUsrImage( CONST usrFrm:usrInfType ): String;
begin
   if usrFrm.picture_png = '' then
     showUsrImage := '/../../empty.png'
    else
     showUsrImage := 'data:image/png;base64,' + EncodeBase64( usrFrm.picture_png );
end;


function make_Header_Accnt( CONST myPara:paraType ): String;
begin
  make_Header_Accnt := MenuS_1;
  make_Header_Accnt := sUpdate ( make_Header_Accnt, '%%0', 'sesn=' + myPara.VSession );
end;


function make_Header_APosts( CONST myPara:paraType ): String;
begin
  make_Header_APosts := MenuS_1i;
  make_Header_APosts += '<li><a href="' + cgiPath + 'forum?%%0&ID=%%1">Forum: %%2</a></li>' +
                        '<li><a href="' + cgiPath + 'newthm?%%0&ID=%%1">Thema: %%3</a></li>' +
                        MenuS_2;
  make_Header_APosts  := sUpdate ( make_Header_APosts, '%%0', 'sesn=' + myPara.VSession );
  make_Header_APosts  := sUpdate ( make_Header_APosts, '%%1', myPara.sID );
  make_Header_APosts  := sUpdate ( make_Header_APosts, '%%2', myPara.sPst );
  make_Header_APosts  := sUpdate ( make_Header_APosts, '%%3', myPara.sTopic );

end;



function make_Header_UPosts( CONST myPara:paraType ): String;
begin
  make_Header_UPosts := MenuS_1i;
  make_Header_UPosts += '<li><a href="' + cgiPath + 'info?%%0">Online</a></li>' +
                       '<li class="active"><a href="' + cgiPath + 'upst?%%0&ID=%%1">Nachrichten von: %%2</a></li>' +
                       MenuS_2;

  make_Header_UPosts := sUpdate ( make_Header_UPosts, '%%0', 'sesn=' + myPara.VSession );
  make_Header_UPosts := sUpdate ( make_Header_UPosts, '%%1', myPara.sID );
  make_Header_UPosts := sUpdate ( make_Header_UPosts, '%%2', myPara.Text2 );

end;


function make_Header_Posts( CONST myPara:paraType ): String;
begin
  make_Header_Posts := MenuS_1i;
  make_Header_Posts += '<li><a href="' + cgiPath + 'forum?%%0&ID=%%1">Forum: %%3</a></li>' +
                       '<li class="active"><a href="' + cgiPath + 'topic?%%0&ID=%%1&Tpc=%%2">Thema: %%4</a></li>' +
                       MenuS_2;
  make_Header_Posts := sUpdate ( make_Header_Posts, '%%0', 'sesn=' + myPara.VSession );
  make_Header_Posts := sUpdate ( make_Header_Posts, '%%1', myPara.sID );
  make_Header_Posts := sUpdate ( make_Header_Posts, '%%2', myPara.sPst );
  make_Header_Posts := sUpdate ( make_Header_Posts, '%%3', myPara.sTopic );
  make_Header_Posts := sUpdate ( make_Header_Posts, '%%4', myPara.text2 );

end;

function make_Header_Forum( CONST myPara:paraType ): String;
begin
  make_Header_Forum := MenuS_1;
  if mypara.sCmd = '1' then
    begin
      make_Header_Forum += '<li class="active"><a href="' + cgiPath + 'forum?%%0&ID=%%1">Forum: %%2</a></li>' +
                           '<li><a href="' + cgiPath + 'newthm?%%0&ID=%%1">Neues Thema</a></li>' +
                           MenuS_2;
      make_Header_Forum := sUpdate ( make_Header_Forum, '%%0', 'sesn=' + myPara.VSession );
      make_Header_Forum := sUpdate ( make_Header_Forum, '%%1', myPara.sID );
      make_Header_Forum := sUpdate ( make_Header_Forum, '%%2', myPara.sTopic );
    end
   else
   make_Header_Forum := sUpdate( make_Header_Forum, '%%0', '' );
end;


function make_Header_newThm( CONST myPara:paraType ): String;
begin
  make_Header_newThm := MenuS_1i;
  if mypara.sCmd = '1' then
    begin
      make_Header_newThm += '<li><a href="' + cgiPath + 'forum?%%0&ID=%%1">Forum: %%2</a></li>' +
                            '<li class="active"><a href="' + cgiPath + 'newthm?%%0&ID=%%1">Neues Thema</a></li>' +
                            MenuS_2;
      make_Header_newThm := sUpdate ( make_Header_newThm, '%%0', 'sesn=' + myPara.VSession );
      make_Header_newThm := sUpdate ( make_Header_newThm, '%%1', myPara.sID );
      make_Header_newThm := sUpdate ( make_Header_newThm, '%%2', myPara.sTopic );
    end
   else
   make_Header_newThm := sUpdate( make_Header_newThm, '%%0', '' );
end;


function make_Header( CONST myPara:paraType ): String;
begin
  make_Header := MenuS_1;
  if mypara.sCmd = '1' then
    begin
      make_Header += '<li><a href="' + cgiPath + 'myacc?%%0"> Mein Konto </a></li>' +
                     MenuS_2;
      make_Header := sUpdate ( make_Header, '%%0', 'sesn=' + myPara.VSession );
    end
   else
   make_Header := sUpdate( make_Header, '%%0', '' );
end;

/////////////////////////////////////////////////
// preset mypara.sCmd      0: no Session 1: Active Session
//        myPara.VSession  Session ID
//
function make_Footer( CONST conn: TMySQL55Connection; CONST myPara:paraType ): String;
VAR
  sTmp : string;
  sesnRec : sessInfType;

begin

  make_Footer := FootStr;

  /// normailze sesnRec
  if mypara.sCmd = '1' then         // session valid flag
    begin
      make_Footer := sUpdate ( make_Footer, '%%0', '&sesn=' + myPara.VSession );
      sesnRec.id  := mypara.VSession;
      sesn_Read( conn, sesnRec);
      /// save forward page for fevent in
      /// sesnRec.forwarded_for:= 'legal?actn=' + mypara.text1;
      sesnRec.forwarded_for:= myPara.text1;
      sesnRec.lastsearch   := myPara.text2;
      sesnRec.v_rec        := myPara.v_rec;
      sesnRec.v_eof        := myPara.v_eof;
      sesnRec.v_page       := mypara.v_page;
      if sesnRec.v_page = '' then sesnRec.v_page := '0';
      sTmp := sesn_update ( conn, sesnRec);
      /// exit on save error
      if sTmp <> '' then
        begin
         make_Footer += sTmp;
         exit;
        end;
    end
   else
    begin
      make_Footer    := sUpdate( make_Footer, '%%0', iif( myPara.VSession <> '', '&sesn=' + myPara.VSession, '' ));
      sesnRec.v_page := '0';                               // no navi btns
      sesnRec.v_rec  := '1';
      sesnRec.v_order:= '1';
      sesnRec.v_eof  := '0';
    end;

  // parse vpage string to set display order & display page
  make_Footer += '<a %%0 class="listLinks"';
  case sesnRec.v_order of
     '1' : make_Footer += ' %%1>Aktualität</a><a %%2 class="listLinks">Größe</a><a %%3 class="listLinks">' ;
     '2' : make_Footer += '>Aktualität</a><a %%2 class="listLinks" %%1>Größe</a><a %%3 class="listLinks">' ;
     '3' : make_Footer += '>Aktualität</a><a %%2 class="listLinks">Größe</a><a %%3 class="listLinks" %%1>' ;
  end;

  // add urls if session is valid
  if mypara.sCmd = '1' then
     begin
      make_Footer := sUpdate ( make_Footer, '%%0', 'href="' + cgiPath + 'event?ev=1&sesn=' + myPara.VSession + '"') ;
      make_Footer := sUpdate ( make_Footer, '%%2', 'href="' + cgiPath + 'event?ev=2&sesn=' + myPara.VSession + '"') ;
      make_Footer := sUpdate ( make_Footer, '%%3', 'href="' + cgiPath + 'event?ev=3&sesn=' + myPara.VSession + '"') ;
     end
    else
     begin
      make_Footer := sUpdate ( make_Footer, '%%0', '' );   // no session -> no links
      make_Footer := sUpdate ( make_Footer, '%%2', '' );
      make_Footer := sUpdate ( make_Footer, '%%3', '' );
     end;

  // highlight selected display order
  make_Footer := sUpdate( make_Footer, '%%1', FootHigh ); //'style="font-weight:bold;color:white;"' );
  make_Footer += 'Alphabetisch</a></div></div></li>';

  // nav items if session is valid
  if mypara.sCmd = '1' then
     begin
      sTmp := '<li><a %%0 %%3 title="Zur Seite ' + sMinus(sesnRec.v_page) + '">&lt;</a></li>' +    // Prev
              '<li><a %%1 %%4 title="Zur Seite ' + sPlus(sesnRec.v_page)  + '">&gt;</a></li>' +    // Next
              '<li><a %%2 title="Eintrag suchen">Finden</a></li>';   // Find
      sTmp := sUpdate ( sTmp, '%%0', 'href="' + cgiPath + 'event?ev=4&sesn=' + myPara.VSession + '&vpage=' + sMinus(sesnRec.v_page) + '&rec=' + sesnRec.v_rec + '"') ;
      sTmp := sUpdate ( sTmp, '%%1', 'href="' + cgiPath + 'event?ev=5&sesn=' + myPara.VSession + '&vpage=' + sPlus(sesnRec.v_page)  + '&rec=' + sesnRec.v_rec + '"') ;
      sTmp := sUpdate ( sTmp, '%%2', 'href="' + cgiPath + 'find?&sesn=' + myPara.VSession + '"') ;
      sTmp := sUpdate ( sTmp, '%%3', iif( myPara.v_page = '0', '', FootHigh ));
      sTmp := sUpdate ( sTmp, '%%4', iif( myPara.v_eof = '1', '', FootHigh ));
      make_Footer += sTmp;
     end;


  // user items if session is valid
  if mypara.sCmd = '1' then
     begin
       sTmp := '<li><a>Freunde</a><div class="one_column_layout">' +
               '<div class="col_1"><a class="headerLinks">Freunde</a></p>' +
               '<a %%0 class="listLinks">OnLine (%%1)</a>' +
               '<a %%2 class="listLinks">Umgebung</a>' +
               '<a %%3 class="listLinks" style="font-weight:bold;color:white;">Nachrichten(' + sesnRec.last_post_cnt + ')</a>' +
               '</div></div></li>';
       sTmp := sUpdate ( sTmp, '%%0', 'href="' + cgiPath + 'info?sesn=' + myPara.VSession + '"') ;
       sTmp := sUpdate ( sTmp, '%%1', sesn_count(conn, sesnRec) );
       sTmp := sUpdate ( sTmp, '%%2', 'href="' + cgiPath + 'geoinfo?sesn=' + myPara.VSession + '"') ;
       sTmp := sUpdate ( sTmp, '%%3', 'href="' + cgiPath + 'news?sesn=' + myPara.VSession + '"') ;
       make_Footer += sTmp;
     end;

  make_Footer += '</ul>';

end;

end.
