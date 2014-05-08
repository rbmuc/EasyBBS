/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 19.03.14
// file      : find.pas
//             search posts & topics
//             for user, headline, date or publish fulltext

unit find;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, mysql55conn, sqldb, blowcryp, mapping, menu;


type
  Tfind = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
  end;

implementation

//////////////////////////////////////////////////////////
// validate bbs_find.html form entries
// show error page on: all empty,
//                     certain paras leading to empty result
// otherwise         : redirect to ./findrslt

procedure Tfind.Post;
var
  I : integer;
  mySessn: sessInfType;
  myPara : paraType;
  memFrm : ForInfType;
  memTpc : TopInfType;
  PstFrm : PstInfType;
  usrFrm1: usrInfType;
  query  : TSQLQuery;
  sRslt, body, sDate : String;

begin

  // read para
  for I := 0 to Fields.Count-1 do
   begin
      case Fields.Names[i] of
        'sesn' : myPara.VSession := Fields.Values[Fields.Names[i]];
        'Tpc'  : myPara.sTopic   := Fields.Values[Fields.Names[i]];
        'user' : myPara.sID      := Fields.Values[Fields.Names[i]];
        'date' : myPara.sPst     := Fields.Values[Fields.Names[i]];
        'S1'   : myPara.text2    := Fields.Values[Fields.Names[i]];
        'B2'   : myPara.sCmd     := Fields.Values[Fields.Names[i]];
        'B3'   : myPara.sCmd     := Fields.Values[Fields.Names[i]];
      end;
    end;

  // cancel on quit
  if myPara.sCmd = 'quit' then
  begin
    redirect ('main?sesn=' + myPara.VSession, 302);
    exit
  end;

  // cancel on unknown command
  if myPara.sCmd <> 'find' then
  begin
    Render(err_page, ['unknow command: ' + myPara.sCmd]);
    exit
  end;

  // exit on invalid session
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  // read session rec
  mySessn.id  := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

  // avoid code injection
  myPara.sTopic := SecuredStr(myPara.sTopic);                // headline
  myPara.sID    := SecuredStr(myPara.sID);                   // author
  myPara.sPst   := SecuredStr(myPara.sPst);                  // publish date
  myPara.text2  := SecuredStr(myPara.text2);                 // medium blob text


  // exit on all empty
  if (myPara.sTopic = '') AND
     (myPara.sID = ''   ) AND
     (myPara.sPst = ''  ) AND
     (myPara.text2 = '' ) then
    begin
     Render(err_page, ['Keine Suchangaben ..']);
     exit;
    end;

  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;

  /////////////////////////////////
  // entry fields check queries
  sRslt := '';
  myPara.lastError := '';

  // search author
  if myPara.sID <> '' then
    begin
      // find user(s)
      sRslt := 'WHERE Name like "%' + myPara.sID + '%" ';
      query.SQL.Text := 'select * from user where name like "%' + myPara.sID +'%"' ;
      query.Open;
      if query.eof then myPara.lastError += 'Keine Author(en) gefunden: ' + myPara.sID + '</p>';
      query.active := False;
    end;

  // search Headline in posts and topics - valid on any result
  if myPara.sTopic <> '' then
    begin
      sRslt += iif(sRslt='','WHERE ',' AND ') + '( post_subject like "%' + myPara.sTopic + '%" OR title like "%' + myPara.sTopic + '%" ) ';
      query.SQL.Text := 'SELECT * FROM posts where post_subject like "%' + myPara.sTopic + '%";';
      query.Open;
      if query.eof then
        begin
         query.active := False;
         query.SQL.Text := 'SELECT * FROM topics where title like "' + myPara.sTopic + '%";';
         query.Open;
         if query.eof then myPara.lastError += 'Kein Thema oder Nachricht mit Überschrift: ' + myPara.sTopic + '</p>';
        end;
      query.active := False;
    end;

  // search Date in posts and topics - valid on any result
  if myPara.sPst <> '' then
    begin
      sDate := FormatDateTime('yyyy-mm-dd', StrToDate(myPara.sPst));
      sRslt += iif(sRslt='','WHERE ',' AND ') + 'post_time like "' + sDate +'%" ' ;
      query.SQL.Text := 'SELECT * FROM posts where post_time like "' + sDate + '%" OR post_edit_time like "' + sDate + '%";';
      query.Open;
      if query.eof then
        begin
         query.active := False;
         query.SQL.Text := 'SELECT * FROM topics where ctime like "' + sDate + '%" OR last_post_time like "' + sDate + '%";';
         query.Open;
         if query.eof then myPara.lastError += 'Keine Themen oder Nachrichten am: ' + sDate + '</p>';
        end;
      query.active := False;
    end;

  // search text in blob
  if myPara.text2 <> '' then
    begin
      myPara.text2 := StripHTML( myPara.text2 );
      sRslt += iif(sRslt='','WHERE ',' AND ') + 'match(post_text) AGAINST ("' + myPara.text2 + '" IN NATURAL LANGUAGE MODE) ';
      query.SQL.Text := 'select * from posts where match ( post_text ) AGAINST (''' + myPara.text2 + ''' IN NATURAL LANGUAGE MODE);';
      query.Open;
      if query.eof then myPara.lastError += 'Keine Nachricht mit Inhalt: ' + myPara.text2 ;
      query.active := False;
    end;

  sRslt := 'SELECT * from find ' + sRslt;

  // exit if one search para leads to empty result
  if myPara.lastError <> '' then
    begin
     query.Free;
     Render(err_page, [myPara.lastError]);
     exit;
    end;


  //////////////////////
  // main query
  query.SQL.Text := sRslt;
  query.Open;

  // exit if combined paras leads to empty result
  if query.eof then
    begin
     sRslt := sUpdate( findinfo,'%%5', myPara.sTopic + '.<br>');
     sRslt := sUpdate( sRslt,   '%%6', myPara.sID + '.<br>');
     sRslt := sUpdate( sRslt,   '%%7', myPara.sPst + '.<br>');
     sRslt := sUpdate( sRslt,   '%%8', myPara.text2 + '.<br>');
     Render(err_page, ['Keine Ergebnisse für <br>' + sRslt]);
     query.active := False;
     query.Free;
     exit;
    end;

  // update session rec with blob search
  mySessn.lastsearch:= myPara.text2 ;
  sesn_update( BrookFCLFCGIBroker.conn, mySessn );

  // open find result
  redirect ('frslt?ID=' + myPara.sID + '&Tpc=' + myPara.sTopic +
            '&Pst=' + myPara.sPst + '&sesn=' + myPara.VSession,
            302);

  // release mem
  query.active := False;
  query.Free;


end;

//////////////////////////////////////////////////////////
// render bbs_find.html form
//        add session info to header & footer
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

procedure Tfind.Get;
var
  I : integer;
  sMenu  : String;
  mySessn: sessInfType;
  myPara : paraType;


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
  paraTypeInit('find?', myPara );                            // init mypara
  mypara.sCmd := '1';                                        // '1' full header menu
  mySessn.id  := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

  sMenu := make_header(mypara);
  mypara.sCmd := '0';                                        // no nav or search in footer

 // display
  Render('bbs_find.html', [ sMenu,
                            mypara.VSession,
                            make_footer( BrookFCLFCGIBroker.conn, mypara)]);


end;

initialization
  Tfind.Register('find');

end.

