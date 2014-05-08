/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 11.02.14
// file      : newThm.pas
// modified  : 12.03.14
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
// called via: 'cgi1/forum?ID=XXXX&sesn=XXXXXXXXXXXXXXX'

unit newThm;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

type
  TnewThm = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
  end;

implementation

procedure TnewThm.Get;
VAR
  memQry : ForInfType;
  memTpc : TopInfType;
  usrFrm1: usrInfType;
  myPara : ParaType;

begin

 // check paras
  memTpc.forum_id := Params.Values['ID'];
  myPara.VSession := Params.Values['sesn'];
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

 if memTpc.forum_id = '' then
    begin
      Render(err_page, ['Forum ID fehlt.']);
      exit;
    end;

  // copy from db to record
  ReadForum( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memQry );
  ReadUsr  ( BrookFCLFCGIBroker.conn, 'where iduser=' + IntToStr(myPara.userID), usrFrm1 );

  // start render
  myPara.Text1 := 'newthm?' ;         // saved in session.forward_for
  myPara.sID   := memTpc.forum_id ;
  myPara.sTopic:= memQry.fName ;

  Render('bbs_newthm.html', [ make_Header_newThm(mypara),
                              showUsrImage(usrFrm1),         // Usr Image
                              showUsrInfo(usrFrm1),          // Usr Info
                              usrFrm1.Name,                  // Column 2 Usr Name
                              memQry.fName,                  // Column 2 Forum Name
                              mypara.VSession,
                              memTpc.forum_id,
                              make_Footer( BrookFCLFCGIBroker.conn, mypara ) ]);


end;


procedure TnewThm.Post;
VAR
  memFrm : ForInfType;
  memTpc : TopInfType;
  usrFrm1: usrInfType;
  sNotify: string;
  myPara : ParaType;

begin

 // read para
  sNotify          := Fields.Values['vsbl'];
  myPara.VSession  := Fields.Values['sesn'];
  mypara.sCmd      := Fields.Values['B1'];
  mypara.sCmd      += Fields.Values['B2'];        // form posts B1 or B2
  memTpc.forum_id  := Fields.Values['forum'];
  memTpc.title     := Fields.Values['tpc_name'];
  memTpc.topic_text:= Fields.Values['S1'];
 // check session
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  // check submit button
  if mypara.sCmd <> 'Senden' then redirect ('./main?sesn=' + mypara.VSession, 302);

  usrFrm1.iduser := inttostr( mypara.userID );
  memTpc.poster  := usrFrm1.iduser;


  ReadForum( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memFrm );
  ReadUsr  ( BrookFCLFCGIBroker.conn, 'where iduser=' + usrFrm1.iduser, usrFrm1 );
  memTpc.poster_name := usrFrm1.Name;

  // insert new topic
  myPara.lastError := topic_insert( BrookFCLFCGIBroker.conn, memTpc );
  if myPara.lastError <> '' then
   begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  // update forum
  memFrm.topics           := sPlus( memFrm.topics );
  memFrm.posts            := sPlus( memFrm.posts );
  memFrm.last_poster_id   := usrFrm1.iduser ;
  memFrm.last_poster_name := usrFrm1.Name;
  memFrm.last_post_subject:= memTpc.title;
  myPara.lastError := Upd_Forum( BrookFCLFCGIBroker.conn, memFrm );
  if myPara.lastError <> '' then
   begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  redirect ('./forum?ID=' + memTpc.forum_id + '&sesn=' + myPara.VSession, 302);

end;

initialization
  TnewThm.Register('newthm');

end.

