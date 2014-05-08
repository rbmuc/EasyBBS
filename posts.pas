////////////////////////////////////////////////////
// project   : bbs_fcgi
// file      : posts.pas
// created   : 02.03.14
// called via: 'cgi1/topic?ID=1;Tpc=1'
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit posts;
{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, DateUtils, mapping, blowcryp, menu;

type
  TPosts = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation



procedure TPosts.Get;
var
  I : Integer;
  sMenu, sBody, sTopic, sTmp, sPage : string;
  memFrm : ForInfType;
  memTpc : TopInfType;
  PstFrm : PstInfType;
  usrFrm1: usrInfType;
  usrFrm2: usrInfType;
  mySessn: sessInfType;
  myPara : paraType;
  query  : TSQLQuery;

begin

 // check paras
  mypara.sip      := TheRequest.RemoteAddress;
  myPara.VSession := Params.Values['sesn'];
  memTpc.forum_id := Params.Values['ID'];
  memTpc.id       := Params.Values['Tpc'];
  sPage           := Params.Values['page'];      //  resest vpage para

  if memTpc.forum_id = '' then
    begin
      Render(err_page, ['Forum ID fehlt: ' + memTpc.forum_id ]);
      exit;
    end;

  if memTpc.id  = '' then
    begin
      Render(err_page, ['Topic ID fehlt: ' + memTpc.id  ]);
      exit;
    end;


  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

 // read forum info
  ReadForum( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memFrm );
 // read session user
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + inttostr(mypara.userID), usrFrm1 );
 // read topic info
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
 // refresh topic access infos
  memTpc.views            := sPlus( memTpc.Views );
  memTpc.last_view_time   := DateTimeToStr( now());
  memTpc.last_poster_name := usrFrm1.Name;
  Topic_Update( BrookFCLFCGIBroker.conn, memTpc );
 // read topic user
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + memTpc.poster, usrFrm1 );

 // render topic
  sTopic := '<div class="fItem">' +
            '<table><tbody>' +
    	    '<tr><td rowspan="3" width=25%%>' +
	    '<img src="%%1" class="usr-image">%%A</td>' +
	    '<td>Erstellt von: %%2 am: %%3 - Letzter Aufruf von: %%4 am: %%5</td>' +
	    '</tr><tr><td>' +
	    '<textarea class="ckeditor" name="S1" id="S1" width="100%">%%6</textarea>' +
            '<script>' +
  		'CKEDITOR.config.readOnly = true;' +
   		'CKEDITOR.config.resize_dir = ''both'';' +
                'CKEDITOR.config.toolbarStartupExpanded = false;' +
                'CKEDITOR.config.toolbarCanCollapse = true;' +
                'CKEDITOR.config.height = ''80px'';' +
              '</script>' +
	    '</td></tr><tr><td>' +
	    '<form style="display: inline-block;" action="' + cgiPath + 'newpst" method="get"> ' +
            '<button name="B1" value="new">Antworten</button>' +
            '<input type="hidden" value="%%7" name="ID">' +
            '<input type="hidden" value="%%8" name="sesn">' +
            '<input type="hidden" value="%%9" name="Tpc">' +
	    '</form>';

  /// show topic edit button if current user = topic creator
  if inttostr( mypara.userID ) = memTpc.poster then
     sTopic += '<form style="display: inline-block;" action="' + cgiPath + 'change" method="get"> ' +
            '<button name="B2" value="chgtpc">Ändern</button>' +
            '<input type="hidden" value="%%7" name="ID">' +
            '<input type="hidden" value="%%8" name="sesn">' +
            '<input type="hidden" value="%%9" name="Tpc">' +
            '</form>' ;

  sTopic += '</td></tr></tbody></table></div><div class="clear"></div><br>';
  sTopic := sUpdate( sTopic, '%%1', showUsrImage(usrFrm1) );
  sTopic := sUpdate( sTopic, '%%2', memTpc.poster_name );
  sTopic := sUpdate( sTopic, '%%3', memTpc.ctime );
  sTopic := sUpdate( sTopic, '%%4', memTpc.last_poster_name );
  sTopic := sUpdate( sTopic, '%%5', memTpc.last_view_time );
  sTopic := sUpdate( sTopic, '%%6', memTpc.topic_text );
  sTopic := sUpdate( sTopic, '%%7', memTpc.id );
  sTopic := sUpdate( sTopic, '%%8', mypara.VSession );
  sTopic := sUpdate( sTopic, '%%9', memTpc.forum_id );
  sTopic := sUpdate( sTopic, '%%A', showUsrInfo(usrFrm1) );
  sBody  := sTopic;

 // read sesion info to set display order
  mySessn.id := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
 // reset page count if spage=0
  if spage = '0' then
    begin
     mySessn.v_page:='0';
     sesn_update( BrookFCLFCGIBroker.conn, mySessn );
    end;

  case mySessn.v_order of
     '0' : sTmp := '' ;
     '1' : sTmp := ' ORDER BY post_time';
     '2' : sTmp := ' ORDER BY post_size';
     '3' : sTmp := ' ORDER BY post_alpha';
  end;


 // set session info
  mypara.sCmd   := '1';                                               // '1' full menus
  myPara.sID    := memTpc.forum_id;
  myPara.sTopic := memFrm.fName ;
  myPara.sPst   := memTpc.id;
  myPara.v_page := mySessn.v_page;
  myPara.Text1  := 'topic?ID=' + memTpc.forum_id + '&Tpc=' + memTpc.id;  // saved in session.forward_for
  myPara.text2  := memTpc.title;

 // read posts info
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'SELECT * FROM posts where topic_id=' + memTpc.id +
                     sTmp +                                           // order by
                     ' limit ' +                                      // limit start,stop
                     IntToStr( StrToInt( mySessn.v_page ) * PageItems )
                     + ',' + IntToStr( StrToInt( mySessn.v_page ) * PageItems + PageItems+1 );
  query.Open;
  if query.EOF then
     begin
        // set menu info for topic w/o posts
        myPara.sID    := memTpc.forum_id;
        myPara.sTopic := memFrm.fName ;
        myPara.sPst   := memTpc.id;
        myPara.text2  := memTpc.title;
        sMenu         :=  make_Header_Posts( myPara );
        mypara.sCmd   := '0';                                         // switch off navi bars in footer
        Render('bbs_thread.html', [sMenu, sBody, make_Footer( BrookFCLFCGIBroker.conn, mypara )] );
        // free mem
        query.active := false;
        query.free;
        exit;
     end;



 // render posted replies
  i := 0;
  sBody := sBody + '<div class="fItem">';
  while not query.EOF do
   begin
    // read
    cpyPostInfo( Query, PstFrm );
    ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + PstFrm.user_id, usrFrm1 );
    ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + PstFrm.post_edit_user, usrFrm2 );

    // build display string
    sTopic := '<table><tbody><tr>' +
  	      '<td>Antwort von: %%1 am: %%2 - Letzter Aufruf von: %%3 am: %%4</td>' +
  	      '<td rowspan="3" width=25%%><img src="%%6" class="usr-image">%%A</td>' +
	      '</tr><tr><td><textarea class="ckeditor" name="S2" id="S2" width="100%">%%5</textarea>' +
              '</td></tr><tr><td>';

    // show post edit buttons if current user = post creator
    if inttostr( mypara.userID ) = PstFrm.user_id then
    sTopic += '<form style="display: inline-block;" action="' + cgiPath + 'change" method="get"> ' +
              '<button name="B2" value="chngpst">Ändern</button>' +
              '<button name="B3" value="deltpst">Löschen</button>' +
              '<input type="hidden" value="%%7" name="ID">' +
              '<input type="hidden" value="%%8" name="sesn">' +
              '<input type="hidden" value="%%9" name="Pst">' +
              '</form>' ;

    sTopic += '</td></tr></tbody></table>' ;
    sTopic := sUpdate( sTopic, '%%1', usrFrm1.Name );
    sTopic := sUpdate( sTopic, '%%2', PstFrm.post_time );
    sTopic := sUpdate( sTopic, '%%3', usrFrm2.Name );
    sTopic := sUpdate( sTopic, '%%4', PstFrm.post_edit_time );
    sTopic := sUpdate( sTopic, '%%5', PstFrm.post_text );
    sTopic := sUpdate( sTopic, '%%6', showUsrImage(usrFrm1) );
    sTopic := sUpdate( sTopic, '%%A', showUsrInfo(usrFrm1) );

    // set post edit buttons links
    if inttostr( mypara.userID ) = PstFrm.user_id then
      begin
        sTopic := sUpdate( sTopic, '%%7', PstFrm.id );
        sTopic := sUpdate( sTopic, '%%8', mypara.VSession );
        sTopic := sUpdate( sTopic, '%%9', PstFrm.user_id );
      end;
    sBody +=  sTopic + '<BR>';
    i += 1;
    if i = PageItems then break;
    query.next;
   end;
  sBody += '</div><div class="clear"></div><br>';

  mypara.V_rec := query.FieldByName('id').asString;
  if query.EOF then
     mypara.v_eof := '1'
   ELSE
     mypara.v_eof := '0';


 // set menu
  mypara.sCmd   := '1';                                                 // '1' full menus
  myPara.sID    := memTpc.forum_id;
  myPara.sTopic := memFrm.fName ;
  myPara.sPst   := memTpc.id;
  myPara.Text1 := 'topic?ID=' + memTpc.forum_id + '&Tpc=' + memTpc.id;  // saved in session.forward_for
  myPara.text2  := memTpc.title;

 // display topic & posts
  Render('bbs_thread.html', [make_Header_Posts( myPara ),
                             sBody,
                             make_Footer( BrookFCLFCGIBroker.conn, mypara )] );

 // release mem
  query.active := false;
  query.free;

end;


initialization
  TPosts.Register('topic');

end.

