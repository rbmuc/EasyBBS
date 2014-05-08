////////////////////////////////////////////////////
// file      : myAccnt.pas
//             called as 'cgi1/myacc'
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit myAccnt;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, BrookUtils, HTTPDefs, Classes, SysUtils,
  Variants, FmtBCD, sqldb, blowcryp, mapping, menu;

type
  TMyAccnt = class(TBrookAction)
  public
    procedure Get; override;
    procedure Post; override;
  end;

implementation

procedure TMyAccnt.Get;
VAR
  sMenu, sRet : String;
  myPara : ParaType;
  usrFrm1: usrInfType ;


begin
 // check session
  myPara.VSession := Params.Values['sesn'];
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;


 // render record
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + inttostr(myPara.userID), usrFrm1 );
  sRet := sUpdate( accntEdt, '%%1', usrFrm1.Name );
  sRet := sUpdate( sRet, '%%2', usrFrm1.MailAdress );
  sRet := sUpdate( sRet, '%%3', usrFrm1.pwd );
  sRet := sUpdate( sRet, '%%4', usrFrm1.pwd );
  sRet := sUpdate( sRet, '%%5', showUsrImage(usrFrm1) );
  if usrFrm1.isVisible = 'False' then
    sRet := sUpdate( sRet, '%%6', ' ' )
  else
    sRet := sUpdate( sRet, '%%6', 'checked ="true"' );

  sRet := sUpdate( sRet, '%%7', mypara.VSession );

  mypara.sCmd := '1';
  sMenu := make_Header( myPara ) ;
  // don't show navi buttons
  mypara.sCmd := '0';
  Render('bbs_myacc.html', [sMenu,
                            sRet,
                            make_Footer(BrookFCLFCGIBroker.conn,mypara) ]);

end;




procedure TMyAccnt.Post;
VAR
  i : integer;
  vPWD2, vagb, sRet : String;
  myPara : ParaType;
  usrFrm : usrInfType ;
  usrFrm1: usrInfType ;
  Stream : TMemoryStream;
  VFormItem: TUploadedFile;


Begin
  vagb := Fields.Values['agb'];
  vPWD2:= Fields.Values['password_confirm'];

  usrFrm.Name        := Fields.Values['usr_name'];
  usrFrm.MailAdress  := Fields.Values['email'];
  usrFrm.pwd         := Fields.Values['password'];
  usrFrm.isVisible   := Fields.Values['vsbl'];
  usrFrm.picture_png := Fields.Values['bild'];
  myPara.VSession    := Fields.Values['sesn'];

 // check session
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;
  usrFrm.iduser := inttostr( myPara.userID );

  // no navi bars
  mypara.sCmd := '0';
  // preset entry fault text
  sRet := accntErr;

  // translate input
  if usrFrm.isVisible = 'on' then
     usrFrm.isVisible := 'True'
   else
     usrFrm.isVisible := 'False';

  // punish code injection
  usrFrm.Name       := SecuredStr( usrFrm.Name );
  usrFrm.pwd        := SecuredStr( usrFrm.pwd );
  usrFrm.MailAdress := SecuredStr( usrFrm.MailAdress );
  if (usrFrm.Name = '') or (usrFrm.pwd ='') or (usrFrm.MailAdress = '')  then
     begin
      sRet := sUpdate (sRet, '%%1', 'SQL Zeichen nicht erlaubt.');
      sRet := sUpdate (sRet, '%%2', 'Aktion abgebrochen !');
      Render('bbs_myacc.html', [make_Header_Accnt(mypara), sRet, make_Footer( conn, mypara ) ]);
      exit;
     end;

  // validate input
  if length( usrFrm.pwd ) < 6 then
     begin
      sRet := sUpdate (sRet, '%%1', 'Ihr Passwort muss mindesten 6 Zeichen lang sein.');
      sRet := sUpdate (sRet, '%%2', 'Bitte korrigieren ..');
      Render('bbs_myacc.html', [make_Header_Accnt(mypara), sRet, make_Footer( conn, mypara )  ]);
      exit;
     end;

  if usrFrm.pwd <> vPWD2 then
     begin
      sRet := sUpdate (sRet, '%%1', 'Passwort und Passwortbestätigung sind ungleich.');
      sRet := sUpdate (sRet, '%%2', 'Bitte korrigieren ..');
      Render('bbs_myacc.html', [make_Header_Accnt(mypara), sRet, make_Footer( conn, mypara )  ]);
      exit;
     end;

  // check input Image
  if usrFrm.picture_png <> '' then
   begin
    // check file type
    if UpperCase(RightStr(usrFrm.picture_png,3))<> 'PNG' then
     begin
       sRet := sUpdate (sRet, '%%1', 'Die Datei ' + usrFrm.picture_png +  '<BR><BR>ist keine PNG Datei.');
       sRet := sUpdate (sRet, '%%2', 'Bitte ändern.');
       Render('bbs_myacc.html', [make_Header_Accnt(mypara), sRet, make_Footer( conn, mypara )  ]);
       exit;
     end;

    VFormItem := Files[0];
    // wait until file exists
    while not fileexists( BrookSettings.DirectoryForUploads +
                          '\' + usrFrm.picture_png) do begin
      sleep(1000);
      // todo : add timeout
    end;
    // copy image from filesystem to string
    Stream := TMemoryStream.Create;
    stream.LoadFromFile( BrookSettings.DirectoryForUploads +
                         '\' + usrFrm.picture_png );
    stream.position := 0;
    // limit png size to db field type mediumtext max
    if stream.size > 124000 then
     begin
       stream.free;
       sRet := sUpdate (sRet, '%%1', 'Die Datei ' + usrFrm.picture_png +  '<BR><BR>ist zu groß. Maximum sind 124 kBytes.');
       sRet := sUpdate (sRet, '%%2', 'Bitte ändern.');
       Render('bbs_myacc.html', [make_Header_Accnt(mypara), sRet, make_Footer( conn, mypara )  ]);
       exit;
     end;
    // set picture_png to hexStr Format
    usrFrm.picture_png := '';
    for i:= 1 to stream.size do
        usrFrm.picture_png += IntToHex(stream.ReadByte,2);
    stream.free;
  end;

 // read user
 ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + usrFrm.iduser, usrFrm1 );
 usrFrm1.Name        := usrFrm.Name ;
 usrFrm1.MailAdress  := usrFrm.MailAdress;
 usrFrm1.pwd         := usrFrm.pwd ;
 usrFrm1.isVisible   := usrFrm.isVisible;
 usrFrm1.picture_png := usrFrm.picture_png;

 // sql update
  myPara.lastError := updUser( BrookFCLFCGIBroker.conn, usrFrm1 );
  if myPara.lastError <> '' then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

  redirect ('./myacc?sesn=' + myPara.VSession, 302);

end;


initialization
  TMyAccnt.Register('myacc');

end.

