/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 11.02.14
// file      : forums.pas
// modified  : 12.03.14
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
// called via: 'cgi1/forum?ID=XXXX&sesn=XXXXXXXXXXXXXXX'

unit forums;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, mapping, blowcryp, menu;

type
  TForum = class(TBrookAction)
  public
    procedure Get; override;
  end;


implementation


procedure TForum.Get;
var
  i : integer;
  sBody, sLink, sInfo, sTmp : string;
  memFrm : ForInfType;
  memTpc : TopInfType;
  mypara : ParaType;
  mySessn: sessInfType;
  query  : TSQLQuery;



begin
  // check paras
  memTpc.forum_id := Params.Values['ID'];
  mypara.VSession := Params.Values['sesn'];
  if memTpc.forum_id = '' then
    begin
      Render(err_page, ['Forum ID fehlt.' ]);
      exit;
    end;
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [mypara.lastError]);
      exit;
    end;

 // read session record
  paraTypeInit('forum?', myPara );         // preset myPara
  mySessn.id := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

  // set display order
  case myPara.v_order of
     '0' : sTmp := '' ;
     '1' : sTmp := ' ORDER BY last_post_time';
     '2' : sTmp := ' ORDER BY views';
     '3' : sTmp := ' ORDER BY title';
  end;

 // read forum info
  ReadForum( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memFrm );

 // query
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'SELECT * FROM topics where forum_id=' +
                     memTpc.forum_id +                            // parent forum
                     sTmp +                                       // order by
                     ' limit ' +                                  // limit start,stop
                     IntToStr( StrToInt( myPara.v_page ) * PageItems )
                     + ',' + IntToStr( StrToInt( myPara.v_page ) * PageItems + PageItems+1 );
  query.Open;

 // loop through records til limit
 // we set limit+1 to use query.eof for navibar handler
  i := 0;
  while not query.EOF do
   begin
     sTmp  := '<table><tbody><tr><td>%%0</td></tr><tr>' +
              '<td>%%1</td></tr></tbody></table>' + #13;

     // sLink sample : <a href="./topic?ID=1&Tpc=1&page=0"> erstes Topic</a>
     // &page=0 used in /topic to reset session.vpage
     sLink := '<a href="./topic?ID=' + memTpc.forum_id +
              '&Tpc=' + query.FieldByName('id').asString +
              '&sesn=' + mypara.VSession + '&page=0"> ' +
              query.FieldByName('title').asString + '</a><BR><small>' +
              LEFTSTR ( query.FieldByName('topic_text').asString, 120) + ' .. </small>' ;
     sTmp  := sUpdate ( sTmp, '%%0', sLink );       // para %%0 : title

     // sInfo sample : <B>von: </B>Kleeblatt<B> am: </B>30.12.2013<B> Hits: </B>0<B> Posts: </B>0
     sInfo := '<B> erstellt von: </B>' + query.FieldByName('poster_name').asString +
              '<B> am: </B>'    + query.FieldByName('ctime').asString +
              '<B> Zugriffe: </B>'  + query.FieldByName('views').asString +
              '<B> Antworten: </B>' + query.FieldByName('replies').asString;
     sTmp  := sUpdate ( sTmp, '%%1', sInfo );       // para %%1 : info
     sBody += sTmp;
     i += 1;
     if i = PageItems then break;
     query.next;
   end;

 // build mypara for header & footer menus
  mypara.sCmd  := '1';                              // '1' full record
  myPara.v_eof := iif( query.EOF, '1', '0');        // eof flag
  mypara.V_rec := query.FieldByName('id').asString; // last recid
  mypara.Text1 := 'forum?ID=' + memTpc.forum_id;    // saved in session.forward_for
  mypara.sID   := memTpc.forum_id ;                 // Header Menu Para
  mypara.sTopic:= memFrm.fName ;                    // Header Menu Text

 // display
  Render('bbs_topic.html', [make_Header_newThm(mypara),
                            sBody,
                            make_Footer( BrookFCLFCGIBroker.conn, mypara )]) ;

 // release db
  query.active := false;
  query.free;

end;



initialization
  TForum.Register('forum');
end.

