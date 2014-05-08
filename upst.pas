/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 10.03.14
// file      : upst.pas
//            show user posts for select or current user
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit upst;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;


type
  TUpst = class(TBrookAction)
  public
    procedure Get; override;
  end;


implementation


procedure TUpst.Get;
Var
  i,lastID: integer;
  sBody, sTmp : String;
  usrFrm1 : usrInfType;
  myPara  : paraType;
  mySessn : sessInfType;
  query   : TSQLQuery;


begin

 // read paras
  myPara.VSession := Params.Values['sesn'];
  myPara.sID      := Params.Values['ID'];
 // check session
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

 // session callback target
  paraTypeInit('upst?ID=' + myPara.sID, myPara );
  mypara.sCmd := '1';                                                  // '1' full menus
 // read sesion info
  mySessn.id  := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

 // set session info
  if myPara.sID = '' then  myPara.sID := IntToStr( myPara.userID );    // show logon user postings
  mypara.sCmd   := '1';                                                // '1' full menus

 // set display order
  case myPara.v_order of
     '0' : sTmp := '' ;
     '1' : sTmp := ' ORDER BY topics.forum_id';
     '2' : sTmp := ' ORDER BY topics.topic_text';
     '3' : sTmp := ' ORDER BY topics.ctime';
  end;


 // read session user
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + mypara.sID, usrFrm1 );
  sBody := sUpdate( usrTbl,'%%0', showUsrImage(usrFrm1) );
  sBody := sUpdate( sBody, '%%1', count_usr_themes(BrookFCLFCGIBroker.conn, usrFrm1) );
  sBody := sUpdate( sBody, '%%2', count_usr_posts(BrookFCLFCGIBroker.conn, usrFrm1) + showUsrInfo(usrFrm1) );

  myPara.Text2 := usrFrm1.Name;

  // read forums and child posts
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'SELECT * FROM topics left join posts on ( topics.id = posts.forum_id ) ' +
                    'WHERE topics.poster =' + mypara.sID + ' OR posts.user_id =' + mypara.sID +
                    sTmp +                                                // set order
                    ' limit ' +                                           // limit start,stop
                    IntToStr( StrToInt( mySessn.v_page ) * PageItems )
                    + ',' + IntToStr( StrToInt( mySessn.v_page ) * PageItems + PageItems+1 );
  query.Open;

  i := 0;
  while not query.EOF do
   begin
    if query.FieldByName('forum_id').AsInteger <> lastID then
      begin
        sTmp := sUpdate( tpcTbl,'%%3', query.FieldByName('title').AsString );
        sTmp := sUpdate( sTmp,  '%%4', query.FieldByName('ctime').AsString );
        sTmp := sUpdate( sTmp,  '%%5', query.FieldByName('topic_text').AsString );
        sBody += sTmp;
      end;

    if query.FieldByName('user_id').IsNull = false then
      begin
        sTmp := sUpdate( pstTbl,'%%6', query.FieldByName('post_time').AsString );
        sTmp := sUpdate( sTmp,  '%%7', query.FieldByName('post_text').AsString );
        sBody += sTmp;
      end;


    lastID := query.FieldByName('id').AsInteger;
    i += 1;
    if i = PageItems then break;
    query.next;
   end;

  mypara.V_rec := IntToStr(lastID);          // rec id
  myPara.v_eof := iif( query.EOF, '1', '0'); // eof flag

 // display
  Render('bbs_upst.html', [make_Header_UPosts( myPara ),
                           sBody ,
                           make_Footer( BrookFCLFCGIBroker.conn, myPara ) ]);


 // release mem
  query.active := false;
  query.free;


end;

initialization
  TUpst.Register('upst');

end.

