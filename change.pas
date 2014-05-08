////////////////////////////////////////////////////
// file      : change.pas
// erstellt  : 01.03.14
// called via: 'cgi1/change?B2=xx&ID=xx&sesn=xx&Pst=xx
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0


unit change;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils,
  Variants, FmtBCD, sqldb, mapping, blowcryp, menu;


type
  TChange = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
    procedure HandlePst( VAR myPara: ParaType);
    procedure InfoPstDelete( VAR myPara: ParaType);
    procedure EditTpc  ( VAR myPara: ParaType );
    procedure PstDelete( VAR myPara: ParaType );
    procedure Pst_Save ( VAR myPara: ParaType );
    procedure Tpc_Save ( VAR myPara: ParaType );
   end;

implementation


////////////////////////////////////////////////////////////
// show post form in edit mode
//
procedure TChange.HandlePst( VAR myPara: ParaType);
 VAR
 memFrm : ForInfType ;
 memTpc : TopInfType ;
 PstFrm : PstInfType ;
 usrFrm1: usrInfType ;
 mySessn: sessInfType;


begin

  // read session record
  paraTypeInit('change?', myPara );
  mySessn.id := mypara.VSession;
  sesn_Read( conn, mySessn );
  sesn_copy_para( mySessn, myPara );


  // read posts record
  PstFrm.id := myPara.sID;
  posts_read( BrookFCLFCGIBroker.conn, PstFrm );
  if PstFrm.id = '' then
     begin
      Render(err_page, ['Posting ID fehlt.']);
      exit;
     end;

  // read related records
  memTpc.id := PstFrm.topic_id;
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
  ReadUsr( BrookFCLFCGIBroker.conn, 'WHERE iduser=' + PstFrm.user_id, usrFrm1 );
  ReadForum ( BrookFCLFCGIBroker.conn, 'where id=' + PstFrm.forum_id, memFrm );


  // start render
  myPara.sID := memTpc.forum_id;
  myPara.sPst := memFrm.fName;
  myPara.sTopic := memTpc.title;

  Render('bbs_editpst.html', [make_Header_APosts( myPara ),  // Header Menu
                              showUsrImage(usrFrm1),         // UsrImage(conn, usrFrm1.iduser),
                              showUsrInfo(usrFrm1),          // Usr Info
                              usrFrm1.Name,                  // Column 2 Usr Name
                              memFrm.fName,                  // C2 Topic Header
                              PstFrm.post_subject,           // C2 Theme - editable
                              PstFrm.post_text,              // C2 Text  - editable
                              myPara.VSession,
                              PstFrm.id,
                              make_Footer( BrookFCLFCGIBroker.conn, mypara ) ]);

end;

procedure TChange.InfoPstDelete( VAR myPara: ParaType);
 VAR
 sBody  : String;
 PstFrm : PstInfType;
 memFrm : ForInfType ;
 memTpc : TopInfType ;
 usrFrm1: usrInfType;
 mySessn: sessInfType;


begin

 // read session record
  paraTypeInit('change?', myPara );
  mySessn.id := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

 // read posts record
  PstFrm.id := myPara.sID;
  posts_read( BrookFCLFCGIBroker.conn, PstFrm );
  if PstFrm.id = '' then
     begin
      Render(err_page, ['Posting ID fehlt.']);
      exit;
     end;

 // read related recs
  memTpc.id:= PstFrm.topic_id;
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
  ReadUsr( BrookFCLFCGIBroker.conn, 'WHERE iduser='+PstFrm.user_id, usrFrm1 );
  ReadForum ( BrookFCLFCGIBroker.conn, 'where id=' + PstFrm.forum_id, memFrm );

 // delete confirm body
  sBody := sUpdate( delpst,'%%1', usrFrm1.Name );
  sBody := sUpdate( sBody, '%%2', PstFrm.post_time );
  sBody := sUpdate( sBody, '%%3', PstFrm.post_text );
  sBody := sUpdate( sBody, '%%4', PstFrm.id );
  sBody := sUpdate( sBody, '%%5', myPara.VSession );
  sBody := sUpdate( sBody, '%%6', showUsrImage(usrFrm1));
  sBody := sUpdate( sBody, '%%7', showUsrInfo(usrFrm1));

  // start render
  mypara.sCmd := '0';                                       // '0' no navi btns
  myPara.sID := memTpc.forum_id;
  myPara.sPst := memFrm.fName;
  myPara.sTopic := memTpc.title;

  Render('bbs_thread.html', [make_Header_APosts( myPara ),  // header
                             sBody,                         // topic record
                             make_Footer(BrookFCLFCGIBroker.conn,mypara)] );   // footer

end;

procedure TChange.EditTpc( VAR myPara: ParaType);
 VAR
 memFrm : ForInfType ;
 memTpc : TopInfType ;
 usrFrm1: usrInfType ;


begin


  // copy to record
  memTpc.id:= myPara.sID;
  Topic_Read( conn, memTpc );
  ReadForum ( conn, 'where id=' + memTpc.forum_id, memFrm );
  ReadUsr   ( conn, 'where iduser=' +  memTpc.poster, usrFrm1 );

  // start render
  mypara.sCmd := '0';                                       // '0' no navi btns
  myPara.sID := memTpc.forum_id;
  myPara.sPst := memFrm.fName;
  myPara.sTopic := memTpc.title;
  Render('bbs_edithm.html', [ make_Header_APosts( myPara ), // header
                              showUsrImage(usrFrm1),        // Usr Image
                              showUsrInfo(usrFrm1),         // Usr Info
                              usrFrm1.Name,                 // Column2 Usr Name
                              memFrm.fName,                 // Column2 Forum Name
                              memTpc.title,                 // Column2 Thema Header - editable
                              memTpc.topic_text,            // Column2 Thema Text - editable
                              myPara.VSession,              // Hidden Session ID
                              memTpc.id,                    // Hidden Topic ID
                              make_Footer(BrookFCLFCGIBroker.conn ,mypara) ]);  // footer w/o navi

end;

///////////////////////////////////////////////////////
// procedure   : TChange.Get;
// description : Get Handler for bbs_thread.html form
//               Dispatch to procs

procedure TChange.Get;
 VAR
  mode   : Integer;
  myPara : ParaType;

 begin

 // read paras
  myPara.VSession := Params.Values['sesn'];
  myPara.sTopic   := Params.Values['Tpc'];
  myPara.sPst     := Params.Values['Pst'];
  myPara.sID      := Params.Values['ID'];
  myPara.sCmd     := Params.Values['B2'];
  myPara.sCmd     += Params.Values['B3'];   // form submits B2 or B3
 // check paras
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.LastError]);
      exit;
    end;

  case myPara.sCmd of
     'chgtpc'  : mode := 1;       // change a topic
     'chngpst' : mode := 2;       // change a posting
     'deltpst' : mode := 3;       // delete a posting
   else
    begin
      Render(err_page, ['Funktion fehlt oder unbekannt: ' + myPara.sCmd ]);
      exit;
    end;
  end;

  if (mode = 1) AND (myPara.sTopic = '') then
    begin
      Render(err_page, ['Topic ID fehlt.']);
      exit;
    end;

  if (mode = 2) AND (myPara.sPst = '') then
    begin
      Render(err_page, ['Nachricht ID fehlt.']);
      exit;
    end;

  if (mode = 3) AND (myPara.sPst = '') then
    begin
      Render(err_page, ['Nachricht ID fehlt.']);
      exit;
    end;

  /// call info procedures - last chance for user to abort
  case mode of
     1 : EditTpc(myPara) ;
     2 : HandlePst(myPara) ;
     3 : InfoPstDelete(myPara);
  end;

 end;

/// DELETE Button Action
procedure TChange.PstDelete( VAR myPara: ParaType);
VAR
   PstFrm : PstInfType;
   usrFrm1: usrInfType;
   memFrm : ForInfType ;
   memTpc : TopInfType ;

begin

 // read posts to rescue topic_id, forum_id and user_id
  PstFrm.id := myPara.sID;
  posts_read( BrookFCLFCGIBroker.conn, PstFrm );
  if PstFrm.id = '' then
    begin
      Render(err_page, ['Nachricht fehlt.']);
      exit;
    end;

 // read related recs
  memTpc.id := PstFrm.topic_id;
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
  ReadForum ( BrookFCLFCGIBroker.conn, 'where id=' + PstFrm.forum_id, memFrm );
  ReadUsr(BrookFCLFCGIBroker.conn, 'where iduser=' + PstFrm.user_id, usrFrm1 );

 // delete posting
  myPara.LastError := posts_Delete( BrookFCLFCGIBroker.conn, PstFrm.id );
  if myPara.LastError <> '' then
    begin
      Render(err_page, ['Fehler beim Löschen der Nachricht: ' + myPara.LastError]);
      exit;
    end;

 // refresh counters
  // update topic
  memTpc.views            := sPlus( memTpc.views );
  memTpc.replies          := sMinus( memTpc.replies );
  memTpc.replies_real     := sMinus( memTpc.replies_real );
  memTpc.last_poster_id   := PstFrm.user_id ;
  memTpc.last_poster_name := usrFrm1.Name;
  memTpc.last_view_time   := DateTimeToStr(now) ;

  myPara.LastError := Topic_Update( BrookFCLFCGIBroker.conn, memTpc );
  if myPara.LastError <> '' then
   begin
     Render(err_page, ['Fehler beim Aktualisieren des Themas: ' + myPara.LastError]);
     exit;
   end;

  // update forum
  memFrm.posts            := sMinus( memFrm.posts );
  memFrm.last_poster_id   := usrFrm1.iduser ;
  memFrm.last_poster_name := usrFrm1.Name;
  myPara.LastError := Upd_Forum( BrookFCLFCGIBroker.conn, memFrm );
   if myPara.LastError <> '' then
    begin
      Render(err_page, ['Fehler beim Aktualisieren des Forums: ' +myPara.LastError]);
      exit;
    end;

  redirect ('topic?ID=' + PstFrm.forum_id + '&Tpc=' + PstFrm.topic_id + '&sesn=' + myPara.VSession, 302);
end;

procedure TChange.Pst_Save ( VAR myPara: ParaType);
VAR
   PstFrm : PstInfType;
   usrFrm1: usrInfType;
   memFrm : ForInfType ;
   memTpc : TopInfType ;


begin

  // read posts record
  PstFrm.id := myPara.sID;
  posts_read( BrookFCLFCGIBroker.conn, PstFrm );
  if PstFrm.id = '' then
     begin
      Render(err_page, ['Posting ID zum Update fehlt.' + myPara.sID + '--' ]);
      exit;
     end;

  // read related recs
  memTpc.id := PstFrm.topic_id;
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
  ReadUsr( BrookFCLFCGIBroker.conn, 'WHERE iduser=' + PstFrm.user_id, usrFrm1 );
  ReadForum ( BrookFCLFCGIBroker.conn, 'where id=' + PstFrm.forum_id, memFrm );

  // update posting
  PstFrm.post_subject     := myPara.text1;
  PstFrm.post_text        := myPara.text2;
  PstFrm.post_edit_count  := sPlus( PstFrm.post_edit_count );
  PstFrm.post_edit_time   := DateTimeToStr(now) ;
  PstFrm.post_edit_reason := myPara.sCmd;
  PstFrm.post_edit_user   := usrFrm1.iduser;
  PstFrm.post_alpha       := LeftStr( StripHTML( PstFrm.post_text) , 255 );
  PstFrm.post_size        := IntToStr( Length ( PstFrm.post_text) );
  myPara.lastError := posts_Update( BrookFCLFCGIBroker.conn, PstFrm );
  if myPara.lastError <> '' then
   begin
     Render(err_page, ['Fehler beim Aktualisieren der Nachricht: ' + myPara.lastError]);
     exit;
   end;

   // refresh counters
  // update topic
  memTpc.views            := sPlus( memTpc.views );
  memTpc.last_poster_id   := PstFrm.post_edit_user ;
  memTpc.last_poster_name := usrFrm1.Name;
  memTpc.last_view_time   := DateTimeToStr(now) ;

  myPara.lastError := Topic_Update( BrookFCLFCGIBroker.conn, memTpc );
  if myPara.lastError  <> '' then
   begin
     Render(err_page, ['Fehler beim Aktualisieren des Themas: ' + myPara.lastError ]);
     exit;
   end;

  // update forum
  memFrm.last_poster_id   := PstFrm.post_edit_user ;
  memFrm.last_poster_name := usrFrm1.Name;
  myPara.lastError := Upd_Forum( BrookFCLFCGIBroker.conn, memFrm );
   if  myPara.lastError <> '' then
    begin
      Render(err_page, ['Fehler beim Aktualisieren des Forums: ' + myPara.lastError]);
      exit;
    end;

  redirect ('topic?ID=' + PstFrm.forum_id + '&Tpc=' + PstFrm.topic_id + '&sesn=' + myPara.VSession, 302);
end;


///////////////////////////////////////////
// Save changes to topic
// Save old topic to log
// Update forum's last use
// finish with jump to post page
procedure TChange.Tpc_Save ( VAR myPara: ParaType);
VAR
   sTmp : string;
   memTpc : TopInfType ;


begin

  // read topic
  memTpc.id := myPara.sTopic;
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
  if memTpc.id = '' then
    begin
     Render(err_page, ['Fehler beim Lesen des Themas: ' + myPara.sTopic]);
     exit;
    end;

  // update topic
  memTpc.views          := sPlus( memTpc.views );
  memTpc.title          := myPara.text1;
  memTpc.topic_text     := myPara.text2;
  memTpc.last_view_time := DateTimeToStr(now);
  memTpc.last_post_time := memTpc.last_view_time;

  // save topic
  sTmp := Topic_Update( BrookFCLFCGIBroker.conn, memTpc );
  if sTmp <> '' then
   begin
     Render(err_page, ['Fehler beim Aktualisieren des Themas: ' + sTmp]);
     exit;
   end;

   // go to post page
  redirect ('topic?ID=' + memTpc.forum_id + '&Tpc=' + memTpc.id + '&sesn=' + myPara.VSession, 302);


end;

procedure TChange.Post;
 VAR
 myPara : ParaType;

begin

 // check paras
  myPara.VSession := Fields.Values['sesn'];
  myPara.sTopic   := Fields.Values['Tpc'];
  myPara.sPst     := Fields.Values['Pst'];
  myPara.sID      := Fields.Values['ID'];
  myPara.text1    := Fields.Values['tpc_name'];
  myPara.text2    := Fields.Values['S1'];
  myPara.sCmd     := Fields.Values['B2'];
  myPara.sCmd     += Fields.Values['B3'];
  myPara.sCmd     += Fields.Values['B4'];        // form post Button B2,B3 or B4
  mypara.sip      := TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.LastError]);
      exit;
    end;

  case myPara.sCmd of
     'chgtpc'   : Tpc_Save ( myPara );        // change a topic
     'chngpst'  : Pst_Save ( myPara );        // show posting in bbs_editpst.html
     'deltpst'  : PstDelete( myPara );        // delete a posting
   else
    begin
      Render(err_page, ['Funktion fehlt oder unbekannt: ' + myPara.sCmd ]);
      exit;
    end;
  end;


end;

initialization
  TChange.Register('change');

end.

