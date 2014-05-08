////////////////////////////////////////////////////
// file     : RegisterUsr.pas
//            called as 'cgi1/account'
// modified : 03.03.14
// modified : 24.04.2014 BF 2.6.4 -> BF 3.0.0
// function
// check fields, prompt on non unique vName
// add entry to eaihot table for confirmation mail
// eaihot records are processed by eaihot daemon.
// new & approve account 'cgi1/approve'

unit RegisterUsr;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, SysUtils, Variants,
  FmtBCD, sqldb, mapping, blowcryp, menu;


type
  TAccount = class(TBrookAction)
  public
    procedure Get; override;
  end;

  TApprove = class(TBrookAction)
  public
    procedure get; override;
  end;

implementation


/////////////////////////////////////////////////////////////////
// Confirm Mail Handler:
// .. confirm request by klicking link below:
// http://localhost/cgi-bin/cgi1/approve?ID=38000026016823
procedure TApprove.Get;
var
  sID, sRet  : String;
  myPara : ParaType;
  usrFrm : usrInfType;


begin
  // parse parameters
  myPara.VSession := Params.Values['ID'];
  // no navi bars
  mypara.sCmd := '0';
  sRet :=  '<div class="form-title"><BR><BR>Hallo, <BR>die Aktivierung des Accounts muss innerhalb 24 Stunden <BR>' +
           'erfolgen. Eine spätere Aktivierung ist nicht möglich<BR>Bitte erstellen Sie einen neuen Account.<BR>' +
           '</div><div class="submit-container"><a href="./main?"><img src="../../ok.png" alt="OK" id="ID_OK" /></a></div>';


  // parse session string
  myPara.sIP := TheRequest.RemoteAddress;
  if decodeSessionID( myPara ) > 1440 then
    begin
      Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara )]);
      exit;
    end;


  // ReadUsr
  usrFrm.iduser := IntToStr(myPara.userID);
  ReadUsr( BrookFCLFCGIBroker.conn, 'where iduser=' + usrFrm.iduser, usrFrm );
  if usrFrm.iduser = '' then
     begin
         Render('bbs_accnt.html', [make_Header(mypara),
                                   sRet,
                                   make_Footer( BrookFCLFCGIBroker.conn, mypara )]);
        exit;
     end;

  // update vars
  usrFrm.RegisterIP   := myPara.sIP;
  usrFrm.RegisterTime := DateTimeToStr( now ) ;
  usrFrm.isChecked    := 'True';
  myPara.lastError := updUser(BrookFCLFCGIBroker.conn,usrFrm);
  if myPara.lastError <> '' then
    begin
     Render(err_page, [myPara.lastError]);
     exit;
    end;

  sRet := '<div class="form-title"><BR>Hallo ' + usrFrm.Name + ',<BR>Ihr Account ist aktiviert.<BR>Ihre Mail Adresse: <BR>' +
           usrFrm.MailAdress + '</div><div class="submit-container"><a href="./main?"><img src="../../ok.png" alt="OK" id="ID_OK" /></a></div>';

  Render('bbs_accnt.html', [make_Header(mypara),
                            sRet,
                            make_Footer( BrookFCLFCGIBroker.conn, mypara )]);

end;

procedure TAccount.Get;
var
  i: integer;
  vPWD2, vagb, sRet : string;
  myPara : ParaType;
  usrFrm : usrInfType;
  myJob  : JobType;

begin

  // no navi bars
  mypara.sCmd := '0';


  if Params.Count = 0 then
    begin
      sRet := '<div class="form-title">Benutzername</div>' +
              '<input class="form-field" name="usr_name" type="text" required="required" placeholder="Benutzername"><br>' +
              '<div class="form-title">eMail</div>' +
              '<input class="form-field" name="emailsignup" type="email" required="required" placeholder="user@gmail.com"><br>' +
              '<div class="form-title">Passwort</div>' +
              '<input class="form-field" name="password" required="required" type="password">' +
              '<div class="form-title">Passwort bestätigen</div>' +
              '<input class="form-field" name="password_confirm" required="required" type="password"><br>' +
              '<input type="checkbox" name="agb" required="required">Ich stimme den Nutzungsbedingungen zu<br><br>' +
              '<div class="submit-container"><input class="submit-button" type="submit" value="Anmelden"></div>';
      Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara )]);
      exit;
    end;

// read paras
  vPWD2:= Params.Values['password_confirm'];
  vagb := Params.Values['agb'];

  mypara.VSession   := Params.Values['sesn'];
  usrFrm.Name       := Params.Values['usr_name'];
  usrFrm.MailAdress := Params.Values['emailsignup'];
  usrFrm.pwd        := Params.Values['password'];
 // punish code injection
  usrFrm.Name       := SecuredStr( usrFrm.Name );
  usrFrm.pwd        := SecuredStr( usrFrm.pwd );
  usrFrm.MailAdress := SecuredStr( usrFrm.MailAdress );

 // preset entry fault text
  sRet := accntErr;

 // check paras
  if (usrFrm.Name = '') or (usrFrm.pwd ='') or (usrFrm.MailAdress = '')  then
       begin
        sRet := sUpdate (sRet, '%%1', 'SQL Zeichen nicht erlaubt.');
        sRet := sUpdate (sRet, '%%2', 'Aktion abgebrochen !');
        Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara ) ]);
        exit;
       end;

 // validate input
  if length( usrFrm.pwd ) < 6 then
       begin
        sRet := sUpdate (sRet, '%%1', 'Ihr Passwort muss mindesten 6 Zeichen lang sein.');
        sRet := sUpdate (sRet, '%%2', 'Bitte korrigieren ..');
        Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara )  ]);
        exit;
       end;

  if usrFrm.pwd <> vPWD2 then
       begin
        sRet := sUpdate (sRet, '%%1', 'Passwort und Passwortbestätigung sind ungleich.');
        sRet := sUpdate (sRet, '%%2', 'Bitte korrigieren ..');
        Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara) ]);
        exit;
       end;

 // check if user already exists
  ReadUsr ( conn, ' where name="' + TRIM(usrFrm.Name) + '"', usrFrm );
  if usrFrm.iduser <> '' then
     begin
       sRet := sUpdate (sRet, '%%1', 'Der Benutzername: ' + usrFrm.Name + '<BR>ist leider schon vergeben.<BR>');
       sRet := sUpdate (sRet, '%%2', 'Bitte geben Sie einen anderen Namen ein.');
       Render('bbs_accnt.html', [make_Header(mypara), sRet, make_Footer( conn, mypara) ]);
       exit;
     end;

 // insert new user
  usrFrm.pwd        := encrypt(usrFrm.pwd);
  usrFrm.RegisterIP := TheRequest.RemoteAddress;
  User_insert( BrookFCLFCGIBroker.conn, usrFrm );

 // read again to get recid of new user
  ReadUsr ( BrookFCLFCGIBroker.conn, ' where name="' + TRIM(usrFrm.Name) + '"', usrFrm );
  if usrFrm.iduser = '' then
     begin
       sRet := '<div class="form-title"><BR>Account Info:<BR><BR>Verbindungsfehler.<BR>Bitte später versuchen..<BR></div>' +
              '<div class="submit-container"><a href="./main?"><img src="../../cancel.png" alt="OK" id="ID_CANCEL" /></a></div>';
       Render('bbs_accnt.html', [make_Header(mypara),
                                 sRet,
                                 make_Footer( BrookFCLFCGIBroker.conn, mypara) ]);
       exit;
      end;

 // Insert job 'regmail'
  myJob.inquirer  := conn.UserName;
  myJob.inqIP     := TheRequest.RemoteAddress;
  myJob.iduser    := usrFrm.iduser;
  myJob.Action    := 'regmail';
  myJob.Intervall := '0';
  myJob.Context   := '|';
  job_insert ( BrookFCLFCGIBroker.conn, myJob );

 // render
  sRet := '<div class="form-title"><BR>Account Info:<BR><BR>Account erstellt.<BR>Sie erhalten eine Mail<BR>mit einem Aktivierungslink<BR>an die Mail Adresse<BR>' +
           usrFrm.MailAdress  + '</div><div class="submit-container"><a href="./main?"><img src="../../ok.png" alt="OK" id="ID_OK" /></a></div>';
  Render('bbs_accnt.html', [make_Header(mypara),
                            sRet,
                            make_Footer( conn, mypara) ]);

end;



initialization
  TAccount.Register('accnt');
  TApprove.Register('approve');

end.

