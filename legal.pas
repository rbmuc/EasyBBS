/////////////////////////////////////////////////////////////////////////
// project      : bbs_fcgi
// author       : Ralph Berger
// created      : 02.03.14
// render forms : bbs_terms.html, bbs_imprint.html, bbs_privacy.html
// select via   : legal?actn=1,2,3
// modified     : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit legal;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

type
  TLegal = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure TLegal.Get;
var

  bSessn  : boolean;
  sActn   : String;
  myPara  : ParaType;
  mySessn : sessInfType;
  sMenu, sFooter : string;


begin

  sActn           := Params.Values['actn'];
  mypara.VSession := Params.Values['sesn'];
  if sActn = '' then
     begin
      Render(err_page, ['Action ID fehlt.']);
      exit;
     end;

  // no break on expired session - always render legal forms
  mypara.sip:= TheRequest.RemoteAddress;
  bSessn:= isSessionValid( mypara ) ;

  // preset myPara
  paraTypeInit('legal?actn=' + sActn, myPara );

// read session record
  if bSessn then
    begin
      mySessn.id := mypara.VSession;
      sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
      sesn_copy_para( mySessn, myPara );
    end;

  mypara.sCmd := iif ( bSessn, '1', '0');

  sMenu   := make_Header( mypara );
  sFooter := make_Footer( BrookFCLFCGIBroker.conn, mypara );
  if mypara.lastError <> '' then
     begin
       Render(err_page, [mypara.lastError]);
       exit;
     end;

  // render template
  case sActn of
      '1' : Render('bbs_terms.html', [ sMenu, GetContent( BrookFCLFCGIBroker.conn, 'AGB'), sFooter ]);
      '2' : Render('bbs_terms.html', [ sMenu, GetContent( BrookFCLFCGIBroker.conn, 'Privacy'), sFooter ]);
      '3' : Render('bbs_terms.html', [ sMenu, GetContent( BrookFCLFCGIBroker.conn, 'Imprint'), sFooter ]);
    else
      Render(err_page, ['Action ID unbekannt:' + sActn +'.']);
  end;

end;

initialization
  TLegal.Register('legal');

end.


