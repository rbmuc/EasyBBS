/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 01.03.14
// file      : Logout.pas
//             close session record
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit Logout;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

type
  TGoodBye = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure TGoodBye.Get;
var
  SessRec: sessInfType;
  myPara : ParaType;

begin
 // check session
  myPara.VSession := Params.Values['sesn'];
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      redirect ('./main?',302);
      exit;
    end;

 // close session
  SessRec.user_id := IntToStr( myPara.userID );
  sesn_close( BrookFCLFCGIBroker.conn, SessRec );

 // free mem
  redirect ('./main?',302);

end;

initialization
  TGoodBye.Register('quit');

end.

