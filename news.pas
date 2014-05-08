/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 07.05.14
// file      : news.pas
//             list posts & topics sind last login

unit news;

{$mode objfpc}{$H+}

interface

uses
   BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
   FmtBCD, sqldb, blowcryp, mapping, menu;

type
  Tnews = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure Tnews.Get;
var
  i : integer;
  sRslt, body, sDate : String;
  mySessn: sessInfType;
  myPara : paraType;
  query  : TSQLQuery;

begin

 // read paras
  myPara.VSession := Params.Values['sesn'];

 // check session timeout
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, ['session timeout ' + myPara.lastError + myPara.VSession + inttostr(i) ]);
      exit;
    end;

 // get session info
  paraTypeInit('news?', myPara );                        // init mypara
  mypara.sCmd := '1';                                    // '1' full menus
  mySessn.id  := mypara.VSession;                        // read session rec
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );


 // build query
  sRslt := 'SELECT * from find where post_time > "' +
           FormatDateTime(sqlDate, StrToDateTime(mySessn.lastlogin)) + '" ';

 // set display order
  case myPara.v_order of
     '1' : sRslt += ' ORDER BY post_time';
     '2' : sRslt += ' ORDER BY iduser';
     '3' : sRslt += ' ORDER BY forum_id';
  end;

 // set limit ( start,stop )
  sRslt += ' limit ' +
           IntToStr( StrToInt( myPara.v_page ) * PageItems ) + ',' +
           IntToStr( StrToInt( myPara.v_page ) * PageItems + PageItems+1 );

  //////////////////////
  // main query
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := sRslt;
  query.Open;

  i := 0;
  body := '';
  while not query.EOF do
  begin
    sRslt := sUpdate(findrslt,'%%1','<a href="./forum?ID=' + query.FieldByName('forum_id').AsString +
                                    '&sesn=' + myPara.VSession + '">' +
                                     query.FieldByName('fname').AsString + '</a>' );
    sRslt := sUpdate( sRslt,  '%%2','<a href="./topic?ID=' + query.FieldByName('forum_id').AsString +
                                    '&Tpc=' + query.FieldByName('topic_id').AsString +
                                    '&sesn=' + myPara.VSession + '">' +
                                    query.FieldByName('title').AsString + '</a>'  );
    sRslt := sUpdate( sRslt,  '%%3',StripHTML( query.FieldByName('post_text').AsString) );
    sRslt := sUpdate( sRslt,  '%%4','<a href="./upst?ID=' + query.FieldByName('iduser').AsString +
                                    '&sesn=' + myPara.VSession + '">' +
                                    query.FieldByName('Name').AsString + '</a>'  );
    body += sRslt;
    i += 1;
    if i = PageItems then break;
    query.next;
  end;

  // Build last table line
  sRslt := sUpdate( newsinfo, '%%5', mySessn.lastlogin);
  body += sRslt;

  // set footer info
  myPara.v_eof := iif( query.EOF, '1', '0');                   // eof flag

  // show page
  Render('bbs_news.html', [ make_header(mypara),           // header
                            body,                          // body
                            make_footer( BrookFCLFCGIBroker.conn, mypara) ]); // footer
  // release mem
  query.active := False;
  query.Free;

end;

initialization
  Tnews.Register('news');

end.

