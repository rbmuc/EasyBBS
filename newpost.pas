////////////////////////////////////////////////////
// file : newpost.pas
// created   : 01.03.14
// called via: 'cgi1/newpst?sesn=xxx&ID=1&Tpc=1'
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
unit newPost;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, DateUtils, mapping, blowcryp, menu;

type
  TNewPost = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
  end;

implementation


procedure TNewPost.Get;
VAR
 sBody, sFooter, sMenu, sTopic, sInfo : string;
 memFrm : ForInfType ;
 memTpc : TopInfType ;
 PstFrm : PstInfType ;
 usrFrm1: usrInfType ;
 usrFrm2: usrInfType ;
 myPara : ParaType;

begin

 // check paras
  myPara.VSession := Params.Values['sesn'];
  memTpc.forum_id := Params.Values['Tpc'];
  memTpc.id       := Params.Values['ID'];
  sMenu           := Params.Values['B1'];
  sMenu           += Params.Values['B2'];      // form submits B1 or B2
  if memTpc.forum_id = '' then
    begin
      Render(err_page, ['Forum ID fehlt.']);
      exit;
    end;

  if memTpc.id = '' then
    begin
      Render(err_page, ['Topic ID fehlt.']);
      exit;
    end;
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  PstFrm.user_id  := inttostr( myPara.userID );
  PstFrm.post_time:= FormatDateTime('yyyy-mm-dd hh:nn:ss', now) ;

 // read forum info
  ReadForum( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memFrm );
 // read topic info
  Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
 // read user infos
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + PstFrm.user_id, usrFrm1 );
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + memTpc.poster, usrFrm2 );
 // set menu
  sFooter:= 'ha';
  sMenu := '<li><a href="./main?sesn=%%0"> TeamBBS Forum </a></li>' +
           '<li><a href="' + cgiPath + 'forum?sesn=%%0&ID=%%1"> Forum: %%3 </a></li>' +
           '<li class="active"><a href="' + cgiPath + 'topic?sesn=%%0&ID=%%1&Tpc=%%2"> Thema: %%4 </a></li>' +
           '<li><a href="' + cgiPath + 'quit?sesn=%%0"> Abmelden </a></li>';
  sMenu := sUpdate ( sMenu, '%%0', myPara.VSession );
  sMenu := sUpdate ( sMenu, '%%1', memTpc.forum_id );
  sMenu := sUpdate ( sMenu, '%%2', memTpc.id  );
  sMenu := sUpdate ( sMenu, '%%3', memFrm.fName );
  sMenu := sUpdate ( sMenu, '%%4', memTpc.title );

 // render topic
  sBody  := '<div class="fItem">' ;
  sTopic := '<table><tbody>' +
    	    '<tr><td rowspan="3" width=25%>' +
	    '<img src="%%1" class="usr-image">%%7</td>' +
	    '<td>Erstellt von: %%2 am: %%3 - Letzter Aufruf von: %%4 am: %%5</td>' +
	    '</tr><tr><td>' +
	    '<textarea class="ckeditor" name="S1" readonly>%%6</textarea>' +
	    '</td></tr><tr><td>' +
	    '</td></tr></tbody></table>' ;

  sTopic := sUpdate( sTopic, '%%1', showUsrImage(usrFrm2) );
  sTopic := sUpdate( sTopic, '%%2', memTpc.poster_name );
  sTopic := sUpdate( sTopic, '%%3', memTpc.ctime );
  sTopic := sUpdate( sTopic, '%%4', memTpc.last_poster_name );
  sTopic := sUpdate( sTopic, '%%5', memTpc.last_post_time );
  sTopic := sUpdate( sTopic, '%%6', memTpc.topic_text );
  sTopic := sUpdate( sTopic, '%%7', showUsrInfo(usrFrm2) );

  sBody += sTopic +
           '</div><div class="clear"></div><br>' +
           '<div class="fItem">';
  sTopic := '<table><tbody><tr>' +
            '<td>Neue Antwort von: %%1 am: %%2</td>' +
  	    '<td rowspan="3" width=25%%><img src="%%6" class="usr-image">%%A</td>' +
            '<form method="POST" action="' + cgiPath + 'newpst">' +
	    '</tr><tr><td><textarea class="ckeditor" name="S2" width="100%"></textarea></td>' +
            '<script>' +
  		'CKEDITOR.config.readOnly = false;' +
                'CKEDITOR.config.height = ''120px'';' +
              '</script>' +
            '</tr><tr><td>' +
            '<input type="hidden" value="%%7" name="ID">' +
            '<input type="hidden" value="%%8" name="sesn">' +
            '<input type="hidden" value="%%9" name="Tpc">' +
	    '<input type="submit" value="Senden" name="B1">' +
	    '</form></td></tr></tbody></table>' ;


  sTopic := sUpdate( sTopic, '%%1', usrFrm1.Name );
  sTopic := sUpdate( sTopic, '%%2', PstFrm.post_time );
  sTopic := sUpdate( sTopic, '%%6', showUsrImage(usrFrm1) );
  sTopic := sUpdate( sTopic, '%%7', memTpc.id );
  sTopic := sUpdate( sTopic, '%%8', myPara.VSession );
  sTopic := sUpdate( sTopic, '%%9', memTpc.forum_id );
  sTopic := sUpdate( sTopic, '%%A', showUsrInfo(usrFrm1)  );
  sBody +=  sTopic + '<BR>';
  sBody += '</div><div class="clear"></div><br>';


 // display topic & posts
  Render('bbs_thread.html', [sMenu, sBody, sFooter] );

end;


procedure TNewPost.Post;
VAR
 I : Integer;
 sTmp : string;
 myPara : paraType;
 memFrm : ForInfType ;
 memTpc : TopInfType ;
 PstFrm : PstInfType ;
 usrFrm1: usrInfType ;
 badLst1: TStringList;
 badLst2: TStringList;
 myJob  : JobType;

begin

   mypara.sip       := TheRequest.RemoteAddress;
   myPara.VSession  := Fields.Values['sesn'];
   memTpc.id        := Fields.Values['ID'];
   memTpc.forum_id  := Fields.Values['Tpc'];
   PstFrm.post_text := Fields.Values['S2'];
   if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

   PstFrm.user_id   := IntToStr ( myPara.userID );
   PstFrm.poster_ip := mypara.sip;


  // read forum, topic, user
   ReadForum ( BrookFCLFCGIBroker.conn, 'where id=' + memTpc.forum_id, memFrm );
   Topic_Read( BrookFCLFCGIBroker.conn, memTpc );
   ReadUsr   ( BrookFCLFCGIBroker.conn, 'where iduser=' + PstFrm.user_id, usrFrm1 );

   // cut off bad words
   /// german
   sTmp := GetContent( BrookFCLFCGIBroker.conn, 'bad_de' );
   if sTmp <> 'none' then
     begin
       badLst1 := TStringList.Create;
       badLst1.TextLineBreakStyle := tlbsCRLF;
       badLst1.Text := sTmp;
       for I:=0 to badLst1.Count-1 do
        begin
          PstFrm.post_text:= StringReplace(PstFrm.post_text, TRIM(badLst1[i]),
                                           '/ups/', [rfReplaceAll, rfIgnoreCase]) ;
        end;
       badLst1.Free;
     end;


   /// english
   sTmp := GetContent( BrookFCLFCGIBroker.conn, 'bad_en' );
   if sTmp <> 'none' then
     begin
       badLst2 := TStringList.Create;
       badLst2.TextLineBreakStyle := tlbsCRLF;
       badLst2.Text := sTmp;
       for I:=0 to badLst2.Count-1 do
        begin
          PstFrm.post_text:= StringReplace(PstFrm.post_text, TRIM(badLst2[i]),
                                           '/ups/', [rfReplaceAll, rfIgnoreCase]) ;
        end;
       badLst2.Free;
     end;


   // append posts
   PstFrm.topic_id     := memTpc.id ;
   PstFrm.forum_id     := memTpc.forum_id;
   PstFrm.post_subject := memTpc.title;
   PstFrm.post_alpha   := LeftStr( StripHTML( PstFrm.post_text) , 255 );
   PstFrm.post_size    := IntToStr( Length ( PstFrm.post_text) );
   myPara.lastError := posts_insert( BrookFCLFCGIBroker.conn, PstFrm );
   if myPara.lastError <> '' then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

   // update topic
   memTpc.views            := sPlus( memTpc.views );
   memTpc.replies          := sPlus( memTpc.replies );
   memTpc.replies_real     := sPlus( memTpc.replies_real );
   memTpc.last_poster_id   := PstFrm.user_id ;
   memTpc.last_poster_name := usrFrm1.Name;
   memTpc.last_post_subject:= PstFrm.Post_subject;
   memTpc.last_post_time   := DateTimeToStr (now) ;
   memTpc.last_view_time   := memTpc.last_post_time ;

   myPara.lastError := Topic_Update( BrookFCLFCGIBroker.conn, memTpc );
   if myPara.lastError <> '' then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

   // update forum
   memFrm.topics            := sPlus( memFrm.topics );
   memFrm.posts             := sPlus( memFrm.posts );
   memFrm.last_poster_id    := usrFrm1.iduser ;
   memFrm.last_poster_name  := usrFrm1.Name;
   memFrm.last_post_subject := memTpc.title;
   myPara.lastError := Upd_Forum( BrookFCLFCGIBroker.conn, memFrm );
   if myPara.lastError <> '' then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

   // start job info
   myJob.inquirer  := conn.UserName;
   myJob.inqIP     := PstFrm.poster_ip;
   myJob.Intervall := '0';

   // insert job 'badwords'
   if POS( '/ups/', PstFrm.post_text ) > 0 then
    begin
      myJob.iduser  := PstFrm.user_id ;
      myJob.Action  := 'badwords';
      myJob.Context := '|' + memTpc.id + '|' ;
      job_insert ( BrookFCLFCGIBroker.conn, myJob );
    end;

   // Insert job 'postinfo'
   myJob.iduser  := memTpc.poster;
   myJob.Action  := 'postinfo';
   myJob.Context := '|' + usrfrm1.iduser + '|' + memTpc.id + '|';
   job_insert ( BrookFCLFCGIBroker.conn, myJob );


   redirect ('topic?ID=' + PstFrm.forum_id + '&Tpc=' + PstFrm.topic_id + '&sesn=' + myPara.VSession , 302);


end;

initialization
  TNewPost.Register('newpst');

end.

