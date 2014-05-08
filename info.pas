/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 01.03.14
//        list active users
//        show info tiles ( total , logins, href to user posts( upst )
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit info;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, strutils, sqldb, blowcryp, mapping, menu;

type
  TInfo = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure TInfo.Get;
var
  I : Integer;
  sTiles, kachel, sTmp : string;
  usrFrm1: usrInfType;
  mySessn: sessInfType;
  myPara : paraType;
  query  : TSQLQuery;


begin
 // check session
  mypara.VSession := Params.Values['sesn'];
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;


 // callback target
  paraTypeInit('info?', myPara );                            // init mypara
  mypara.sCmd := '1';                                        // '1' full menus
  mySessn.id  := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

 // set display order
  case myPara.v_order of
     '0' : sTmp := '' ;
     '1' : sTmp := ' ORDER BY login';
     '2' : sTmp := ' ORDER BY latitude, longitude';
     '3' : sTmp := ' ORDER BY user_id';
  end;


  // query
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'select * from sessions where is_active = 1' +
                    sTmp +                                       // order by
                    ' limit ' +                                  // limit start,stop
                    IntToStr( StrToInt( myPara.v_page ) * PageItems )
                    + ',' + IntToStr( StrToInt( myPara.v_page ) * PageItems + PageItems+1 );
  query.Open;

  if query.EOF then
     begin
        query.active := false;
        query.free;
        Render(err_page, ['No Users online.']);
        exit;
     end;

  // loop throug open sessions
  i := 0;
  sTiles := '';
  while not query.EOF do
   begin
     cpySessInfo ( query, mySessn );
     // read session user
     ReadUsr( conn, 'where iduser=' + mySessn.user_id , usrFrm1 );
     // set user tile
     kachel := sUpdate( usrTile,'%%0', mySessn.user_id );                     // UserID
     kachel := sUpdate( kachel, '%%1', iif((i mod 2=1),'rkachel','bkachel')); // tile(red/blue)
     kachel := sUpdate( kachel, '%%2', usrFrm1.Name );                        // UserName
     kachel := sUpdate( kachel, '%%3', showUsrImage(usrFrm1));                // User PNG
     kachel := sUpdate( kachel, '%%4', MIDSTR(mySessn.login,12,5));           // Session start ( HH:MM )
     kachel := sUpdate( kachel, '%%5', usrFrm1.TotalTime );                   // User logins
     kachel := sUpdate( kachel, '%%6', myPara.VSession );                     // Session ID
     sTiles += kachel;
     i += 1;
     if i = PageItems then break;
     query.Next;
   end;

 // prepare & render
  // Update Session info
  myPara.v_rec := mySessn.rid;               // last rec in display
  myPara.v_eof := iif( query.EOF, '1', '0'); // eof flag

  Render('bbs_onln.html', [ make_header(mypara),
                            sTiles,
                            make_footer( BrookFCLFCGIBroker.conn, mypara)]);

 // release mem
  query.active := false;
  query.free;

end;

initialization
  TInfo.Register('info');

end.

