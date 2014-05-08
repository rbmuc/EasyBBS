/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 08.05.14
// file      : main.pas
// called via: cgi1/main?sesn=xx
//         or: cgi1/main for login dialog
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
//           : 27.04.14 - change para read

unit main;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

type
  TWelcome = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
  end;


implementation

procedure TWelcome.Post;
var
  VUser, VPass, VCmd, sTmp : string;
  usrRec : usrInfType;
  sesnRec : sessInfType;


begin

   // post w/o paras? -> only refresh main page ( not logged in )
   if Fields.Count = 0 then
     begin
      redirect ('./main?',302);
      exit;
     end;

   // copy paras
   VUser := SecuredStr(Fields.Values['usr'] );
   VPass := SecuredStr(Fields.Values['pwd'] );
   VCmd  := SecuredStr(Fields.Values['btn'] );
   sesnRec.latitude  := Fields.Values['lat'];
   sesnRec.longitude := Fields.Values['lon'];
   sesnRec.accuracy  := Fields.Values['acc'];


   // check paras
   if (VCmd = 'Anmelden') then
     begin
       if ( VUser = '' ) OR ( VPass = '' ) then
         begin
            Render(err_page, ['Username oder Passwort dürfen nicht leer sein.']);
            exit;
         end;
     end;

   if (VCmd = 'Abbrechen') then
     begin
      redirect ('./main?',302);
      exit;
     end;

   if (VCmd = 'neues Konto') then
     begin
      redirect ('./accnt?',302);
      exit;
     end;


  ReadUsr( BrookFCLFCGIBroker.conn, 'where name = "' + VUser +'"', usrRec );
  if usrRec.name = '' then
    begin
      Render(err_page, ['Username unbekannt']);
      exit;
    end;

 // check pwd
  if usrRec.pwd <> TRIM( VPass ) then
    begin
      Render(err_page, ['Falsches PWD']);
      exit;
    end;

 // check registration
  if usrRec.isChecked <> 'True' then
    begin
      Render(err_page, ['Account nicht aktiviert.']);
      exit;
    end;

 // update user record
  usrRec.picture_png := '';                       // avoid blob save -> speed up
  usrRec.TotalTime   := sPlus(usrRec.TotalTime);  // incr login count
  sesnRec.lastlogin  := usrRec.LastTime;          // rescue old LastLogin
  usrRec.LastTime    := DateTimeToStr( now );     // set login time
  sTmp := updUser( BrookFCLFCGIBroker.conn, usrRec );
  if sTmp <> '' then
    begin
      Render(err_page, [ sTmp ]);
      exit;
    end;

 // add session record
  sesnRec.browser      := TheRequest.UserAgent;
  sesnRec.sip          := TheRequest.RemoteAddress;
  sesnRec.user_id      := usrRec.iduser;                    // add user_id
  codeSessionID( sesnRec );                                 // create sesnRec.id
  sesnRec.is_active    := '1';                              // active = true
  sesnRec.last_forum   := sesnRec.forum_id ;                //
  sesnRec.forum_id     := '0';
  sesnRec.forwarded_for:= 'main?sesn=' + sesnRec.id;
  sesnRec.v_page       := '0';
  sesnRec.v_rec        := '1';
  sesnRec.v_order      := '1';
  sesnRec.v_eof        := '0';
  sesnRec.last_post_cnt:= posts_Count( BrookFCLFCGIBroker.conn, sesnRec.lastlogin );
  GetIPLatLon( GetSetting( BrookFCLFCGIBroker.conn,'GeoIP') + sesnRec.sip,
               sesnRec.sLat, sesnRec.sLong );

  sTmp := sesn_insert ( BrookFCLFCGIBroker.conn, sesnRec);
  if sTmp <> '' then
    begin
      Render(err_page, [sTmp]);
      exit;
    end;

 // show homepage
   redirect ( './main?sesn=' + sesnRec.id, 302 );

end;

{ TWelcome }
procedure TWelcome.Get;
var
  i : integer;
  sTiles, Kachel, sTmp : string;
  bSessn  : boolean;
  myPara  : ParaType;
  memQry  : ForInfType;
  mySessn : sessInfType;
  query   : TSQLQuery;

begin

 // check session
 myPara.VSession := Params.Values['sesn'];
 mypara.sip:= TheRequest.RemoteAddress;
 bSessn:= isSessionValid( mypara );

// preset myPara
  paraTypeInit('main?', myPara );
// read session record
  if bSessn then
    begin
      mySessn.id := mypara.VSession;
      sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
      sesn_copy_para( mySessn, myPara );
    end;

// set display order
  case myPara.v_order of
    '0' : sTmp := '' ;
    '1' : sTmp := ' ORDER BY last_post_time';
    '2' : sTmp := ' ORDER BY posts';
    '3' : sTmp := ' ORDER BY fname';
  end;

 // query
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'select * from forums' +
                    sTmp +                                       // order by
                    ' limit ' +                                  // limit start,stop
                    IntToStr( StrToInt( myPara.v_page ) * PageItems )
                    + ',' + IntToStr( StrToInt( myPara.v_page ) * PageItems + PageItems+1 );
  query.Open;
  if query.EOF then
     begin
        query.active := false;
        query.free;
        Render(err_page, ['No Forums!']);
        exit;
     end;

 // generate tiles
  i := 0;
  sTiles := '';
  while not query.EOF do
   begin
     cpyForumInfo( Query, memQry );
     kachel := iif(bSessn,
                   sUpdate ( tpcTile, '%%6', cgiPath + 'forum?ID=%%0&sesn=' + myPara.VSession ) ,
                   sUpdate ( tpcTile, '%%6', '#" onclick="overlay()') );      // set link
     kachel := sUpdate( kachel, '%%0', memQry.id );                           // ForumID
     kachel := sUpdate( kachel, '%%1', iif((i mod 2=1),'rkachel','bkachel')); // red/blue tile
     kachel := sUpdate( kachel, '%%2', memQry.fname );                        // ForumName
     kachel := sUpdate( kachel, '%%3', memQry.fdesc );                        // Forum Description
     kachel := sUpdate( kachel, '%%4', LEFTSTR(memQry.last_post_time,6) );    // Last post ( DD.MM )
     kachel := sUpdate( kachel, '%%5', memQry.topics );                       // topics#
     sTiles += kachel;
     i += 1;
     if i = PageItems then break;
     query.Next;
   end;


 // Update Session info
  myPara.v_rec := memQry.id;                 // last rec in display
  myPara.Text1 := 'main?';                   // callback target for footer
  myPara.v_eof := iif( query.EOF, '1', '0'); // eof flag
  mypara.sCmd  := iif( bSessn, '1', '0');    // if session full menu else pre login menu

 // render
  Render('bbs_main.html', [ make_Header( mypara ),
                            sTiles,
                            make_Footer( BrookFCLFCGIBroker.conn, mypara ) ]);

 // release mem
  query.active := false;
  query.free;

end;


initialization
  TWelcome.Register('main');

end.
