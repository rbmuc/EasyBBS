/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 20.03.14
// file      : frslt.pas
//             list posts & topics results from find.pas as table
//             use template bbs_findrslt.html
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit frslt;

{$mode objfpc}{$H+}

interface

uses
   BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
   FmtBCD, sqldb, blowcryp, mapping, menu;


type
  Tfrslt = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure Tfrslt.Get;
var
  i : integer;
  sRslt, body, sDate : String;
  mySessn: sessInfType;
  myPara : paraType;
  query  : TSQLQuery;

begin

 // read paras
  myPara.VSession := Params.Values['sesn'];
  myPara.sID      := Params.Values['ID'];
  myPara.sTopic   := Params.Values['Tpc'];
  myPara.sPst     := Params.Values['Pst'];
 // check session timeout
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, ['session timeout ' + myPara.lastError + myPara.VSession + inttostr(i) ]);
      exit;
    end;


 // get session info
  paraTypeInit('frslt?', myPara );                       // init mypara
  mypara.sCmd := '1';                                    // '1' full menus
  mySessn.id  := mypara.VSession;                        // read session rec
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );
  myPara.text1 := 'frslt?ID=' + myPara.sID +             // add search paras
                  '&Tpc=' + myPara.sTopic +
                  '&Pst=' + myPara.sPst +
                  '&sesn=' + myPara.VSession;
  myPara.text2 := mySessn.lastsearch;                    // blob search from session rec


 // build query
  if myPara.sID   <>'' then sRslt += 'WHERE Name like "%' + myPara.sID + '%" ';
  if myPara.sTopic<>'' then sRslt += iif(sRslt='','WHERE ',' AND ') + '( post_subject like "%' + myPara.sTopic + '%" OR title like "%' + myPara.sTopic + '%" ) ';
  if myPara.sPst  <>'' then sRslt += iif(sRslt='','WHERE ',' AND ') + 'post_time like "' + FormatDateTime('yyyy-mm-dd', StrToDate(myPara.sPst)) +'%" ' ;
  if myPara.text2 <>'' then sRslt += iif(sRslt='','WHERE ',' AND ') + 'match(post_text) AGAINST ("' + myPara.text2 + '" IN NATURAL LANGUAGE MODE) ';
  sRslt := 'SELECT * from find ' + sRslt;

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
  // display blanks as ..
  sRslt := sUpdate( findinfo, '%%5', iif( myPara.sTopic='', '..', myPara.sTopic));
  sRslt := sUpdate( sRslt,    '%%6', iif( myPara.sID   ='', '..', myPara.sID));
  sRslt := sUpdate( sRslt,    '%%7', iif( myPara.sPst  ='', '..', myPara.sPst));
  sRslt := sUpdate( sRslt,    '%%8', iif( myPara.text2 ='', '..', myPara.text2));
  body += sRslt;

  // set footer info
  myPara.v_eof := iif( query.EOF, '1', '0');                   // eof flag

  // show page
  Render('bbs_findrslt.html', [ make_header(mypara),           // header
                                body,                          // body
                                make_footer( BrookFCLFCGIBroker.conn, mypara) ]); // footer
  // release mem
  query.active := False;
  query.Free;

end;

initialization
  Tfrslt.Register('frslt');

end.

